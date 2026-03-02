using EventPulse.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using Microsoft.IdentityModel.Tokens;
using StackExchange.Redis;
using Microsoft.AspNetCore.Authentication.JwtBearer;

var builder = WebApplication.CreateBuilder(args);
// Redis Bağlantısı (Singleton olarak tüm uygulamaya dağıtılır)
try 
{
    var multiplexer = ConnectionMultiplexer.Connect("localhost:6379");
    builder.Services.AddSingleton<IConnectionMultiplexer>(multiplexer);
}
catch (Exception ex)
{
    // Redis ayakta değilse uygulama çökmesin diye logluyoruz
    Console.WriteLine($"Redis bağlantı hatası (Cache pasif): {ex.Message}");
}

// RS256 için Bellek İçi (In-Memory) RSA Anahtarı Üretimi
var rsaKey = RSA.Create();
var securityKey = new RsaSecurityKey(rsaKey);
builder.Services.AddSingleton(securityKey);

// DbContext Kaydı (PostgreSQL bağlantı dizesi ile)
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// .NET 8 Swagger/OpenAPI Yapılandırması
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddControllers();
//  Firebase ID Token Doğrulama Middleware'i
var firebaseProjectId = "eventpulseqberx"; // Buraya kendi Firebase Project ID'ni yazmalısın

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = $"https://securetoken.google.com/{firebaseProjectId}";
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = $"https://securetoken.google.com/{firebaseProjectId}",
            ValidateAudience = true,
            ValidAudience = firebaseProjectId,
            ValidateLifetime = true
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddSignalR();

var app = builder.Build();

// Geliştirme ortamı için Swagger Arayüzü
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHub<EventPulse.API.Hubs.EventHub>("/hub/events");

// Test için varsayılan WeatherForecast Endpoint'i
var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast =  Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast");

// Uygulama başlarken bekleyen Migration'ları veritabanına otomatik uygula
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<EventPulse.Infrastructure.Data.AppDbContext>();
    dbContext.Database.Migrate(); 
}

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}