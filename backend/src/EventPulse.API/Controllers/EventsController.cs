using EventPulse.Core.DTOs;
using EventPulse.Infrastructure.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using EventPulse.API.Hubs;
using System.Text.Json;
using StackExchange.Redis;

namespace EventPulse.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EventsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IHubContext<EventHub> _hubContext;
    private readonly IConnectionMultiplexer? _redis; // Redis nesnemiz

    // Constructor'a IConnectionMultiplexer eklendi (Opsiyonel nullable, Redis kapalıysa patlamasın diye)
    public EventsController(
        AppDbContext context, 
        IHubContext<EventHub> hubContext, 
        IConnectionMultiplexer? redis = null)
    {
        _context = context;
        _hubContext = hubContext;
        _redis = redis;
    }

    // GET: api/events
    [HttpGet]
    public async Task<ActionResult<IEnumerable<EventDto>>> GetEvents(
        [FromQuery] string? city,
        [FromQuery] string? category,
        [FromQuery] DateTime? startDate,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        // Cache Key (Her sayfa ve filtre için benzersiz bir anahtar oluşturuyoruz)
        var cacheKey = $"events_{city}_{category}_{startDate}_{page}_{pageSize}";
        var db = _redis?.GetDatabase();

        // 1. ADIM: Redis'te veri var mı diye bak
        if (db != null)
        {
            var cachedData = await db.StringGetAsync(cacheKey);
            if (!cachedData.IsNullOrEmpty)
            {
                // Önbellekte var! JSON'dan listeye çevirip ışık hızında dön
                var cachedEvents = JsonSerializer.Deserialize<List<EventDto>>(cachedData.ToString());
                return Ok(cachedEvents);
            }
        }

        // 2. ADIM: Cache'te yoksa Veritabanından (PostgreSQL) çek
        var query = _context.Events.AsQueryable();

        if (!string.IsNullOrWhiteSpace(city))
            query = query.Where(e => e.City.ToLower() == city.ToLower());
        
        if (!string.IsNullOrWhiteSpace(category))
            query = query.Where(e => e.Category.ToLower() == category.ToLower());

        if (startDate.HasValue)
            query = query.Where(e => e.StartDate.Date == startDate.Value.Date);

        var skip = (page - 1) * pageSize;
        
        var events = await query
            .OrderBy(e => e.StartDate)
            .Skip(skip)
            .Take(pageSize)
            .Select(e => new EventDto
            {
                Id = e.Id,
                Title = e.Title,
                Description = e.Description,
                City = e.City,
                Category = e.Category,
                StartDate = e.StartDate,
                MaxCapacity = e.MaxCapacity,
                CurrentAttendeesCount = e.Attendances.Count
            })
            .ToListAsync();

        // 3. ADIM: Çekilen veriyi 60 saniyeliğine Redis'e yaz (Gelecek istekler için)
        if (db != null)
        {
            var serializedEvents = JsonSerializer.Serialize(events);
            // Vaka çalışması şartı: 60sn cache 
            await db.StringSetAsync(cacheKey, serializedEvents, TimeSpan.FromSeconds(60));
        }

        return Ok(events);
    }

    // GET: api/events/5
    [HttpGet("{id}")]
    public async Task<ActionResult<EventDetailDto>> GetEventDetail(int id)
    {
        var ev = await _context.Events
            .Include(e => e.Attendances)
            .Include(e => e.Comments)
            .FirstOrDefaultAsync(e => e.Id == id);

        if (ev == null)
            return NotFound(new { message = "Etkinlik bulunamadı." });

        var detailDto = new EventDetailDto
        {
            Id = ev.Id,
            Title = ev.Title,
            Description = ev.Description,
            City = ev.City,
            Category = ev.Category,
            StartDate = ev.StartDate,
            MaxCapacity = ev.MaxCapacity,
            CurrentAttendeesCount = ev.Attendances.Count,
            CommentsCount = ev.Comments.Count,
            RecentComments = ev.Comments.OrderByDescending(c => c.CreatedAt).Select(c => c.Content).Take(5).ToList()
        };

        return Ok(detailDto);
    }

    // POST: api/events/5/attend
    [HttpPost("{id}/attend")]
    public async Task<IActionResult> AttendEvent(int id, [FromBody] AttendRequestDto request)
    {
        var ev = await _context.Events
            .Include(e => e.Attendances)
            .FirstOrDefaultAsync(e => e.Id == id);

        if (ev == null)
            return NotFound(new { message = "Etkinlik bulunamadı." });

        if (ev.Attendances.Any(a => a.UserId == request.UserId))
            return BadRequest(new { message = "Bu etkinliğe zaten katıldınız." });

        if (ev.Attendances.Count >= ev.MaxCapacity)
            return BadRequest(new { message = "Etkinlik kapasitesi dolu." });

        var attendance = new EventPulse.Core.Entities.UserAttendance
        {
            EventId = id,
            UserId = request.UserId,
            AttendedAt = DateTime.UtcNow
        };

        _context.UserAttendances.Add(attendance);
        await _context.SaveChangesAsync(); // Veritabanına kaydedildi
       
        // REDIS CACHE INVALIDATION: Etkinliğe katılım oldu, liste güncellenmeli! 
        if (_redis != null)
        {
            var db = _redis.GetDatabase();
            var server = _redis.GetServer(_redis.GetEndPoints().First());
            var keys = server.Keys(pattern: "events_*");
            foreach (var key in keys) {
                await db.KeyDeleteAsync(key);
            }
        }

        //  SIGNALR BROADCAST: Güncel sayıyı hesapla ve o etkinliğin odasındaki (Group) herkese fırlat
        var currentCount = ev.Attendances.Count + 1;
        await _hubContext.Clients.Group($"Event_{id}").SendAsync("ReceiveAttendeeUpdate", id, currentCount);

        return Ok(new { message = "Etkinliğe başarıyla katıldınız." });
    }

    // DELETE: api/events/5/attend
    [HttpDelete("{id}/attend")]
    public async Task<IActionResult> UnattendEvent(int id, [FromBody] AttendRequestDto request)
    {
        var attendance = await _context.UserAttendances
            .FirstOrDefaultAsync(a => a.EventId == id && a.UserId == request.UserId);

        if (attendance == null)
            return NotFound(new { message = "Bu etkinliğe zaten katılmıyorsunuz." });

        _context.UserAttendances.Remove(attendance);
        await _context.SaveChangesAsync(); // Veritabanından silindi

        //  REDIS CACHE INVALIDATION
        if (_redis != null)
        {
            var db = _redis.GetDatabase();
            var server = _redis.GetServer(_redis.GetEndPoints().First());
            var keys = server.Keys(pattern: "events_*");
            foreach (var key in keys) {
                await db.KeyDeleteAsync(key);
            }
        }

        // SIGNALR BROADCAST: Güncel sayıyı hesapla ve fırlat
        var currentCount = await _context.UserAttendances.CountAsync(a => a.EventId == id);
        await _hubContext.Clients.Group($"Event_{id}").SendAsync("ReceiveAttendeeUpdate", id, currentCount);

        return Ok(new { message = "Katılımınız iptal edildi." });
    }

    // POST: api/events/5/comments
    [HttpPost("{id}/comments")]
    public async Task<IActionResult> AddComment(int id, [FromBody] CommentRequestDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var ev = await _context.Events.FindAsync(id);
        if (ev == null)
            return NotFound(new { message = "Etkinlik bulunamadı." });

        var comment = new EventPulse.Core.Entities.Comment
        {
            EventId = id,
            UserId = request.UserId,
            Content = request.Content,
            CreatedAt = DateTime.UtcNow
        };

        _context.Comments.Add(comment);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Yorum başarıyla eklendi." });
    }
}