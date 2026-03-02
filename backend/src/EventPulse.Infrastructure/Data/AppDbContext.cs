using EventPulse.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace EventPulse.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Event> Events => Set<Event>();
    public DbSet<Comment> Comments => Set<Comment>();
    public DbSet<UserAttendance> UserAttendances => Set<UserAttendance>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // 1. Composite PK (Bileşik Anahtar)
        modelBuilder.Entity<UserAttendance>()
            .HasKey(ua => new { ua.UserId, ua.EventId });

        // 2. CHECK Constraint (MaxCapacity > 0)
        modelBuilder.Entity<Event>()
            .ToTable(t => t.HasCheckConstraint("CK_Event_MaxCapacity", "\"MaxCapacity\" > 0"));

        // 3. Content Max 500 Karakter Sınırı
        modelBuilder.Entity<Comment>()
            .Property(c => c.Content)
            .HasMaxLength(500)
            .IsRequired();

        // ---------------------------------------------------
        // 4. SEED DATA (Başlangıç Verileri)
        // ---------------------------------------------------
        
        // ÖNEMLİ: Seed data içinde DateTime.UtcNow kullanmak her build'de yeni migration 
        // oluşmasına sebep olabileceği için sabit (fixed) tarihler kullanıyoruz.
        var event1Date = new DateTime(2026, 5, 15, 14, 0, 0, DateTimeKind.Utc);
        var event2Date = new DateTime(2026, 6, 20, 19, 30, 0, DateTimeKind.Utc);
        var commentDate = new DateTime(2026, 3, 1, 10, 0, 0, DateTimeKind.Utc);

        modelBuilder.Entity<Event>().HasData(
            new Event 
            { 
                Id = 1, 
                Title = "Yazılım Mimari Zirvesi", 
                Description = ".NET 8 ve Flutter ile modern uygulama geliştirme pratikleri.", 
                City = "İstanbul", 
                Category = "Teknoloji", 
                StartDate = event1Date, 
                MaxCapacity = 200 
            },
            new Event 
            { 
                Id = 2, 
                Title = "Açık Hava Rock Konseri", 
                Description = "Sevilen rock gruplarıyla yaza merhaba diyoruz.", 
                City = "İzmir", 
                Category = "Müzik", 
                StartDate = event2Date, 
                MaxCapacity = 5000 
            }
        );

        modelBuilder.Entity<Comment>().HasData(
            new Comment 
            { 
                Id = 1, 
                EventId = 1, 
                UserId = "test_user_1", // Auth eklenene kadar temsili bir string ID
                Content = "Harika bir etkinlik, kesinlikle orada olacağım!", 
                CreatedAt = commentDate 
            }
        );

        base.OnModelCreating(modelBuilder);
    }
}