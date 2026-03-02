using EventPulse.Core.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace EventPulse.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly RsaSecurityKey _rsaKey;

    public AuthController(RsaSecurityKey rsaKey)
    {
        _rsaKey = rsaKey;
    }

    // POST: api/auth/token
    [HttpPost("token")]
    public IActionResult GenerateToken([FromBody] TokenRequestDto request)
    {
        // Mock Doğrulama (Case Study için "123456" şifresi yeterlidir)
        if (string.IsNullOrWhiteSpace(request.Username) || request.Password != "123456")
        {
            return Unauthorized(new { message = "Geçersiz giriş. Şifre '123456' olmalıdır." });
        }

        // 1. JWT İçin Claim'leri (Kullanıcı Bilgilerini) Hazırla
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, request.Username),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim("UserId", request.Username) // Katılım/Yorum işlemlerinde bu ID kullanılacak
        };

        // 2. RS256 Algoritması İle İmzalama
        var credentials = new SigningCredentials(_rsaKey, SecurityAlgorithms.RsaSha256);

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(15), // Kısa ömürlü Access Token
            SigningCredentials = credentials,
            Issuer = "EventPulseAPI",
            Audience = "EventPulseClients"
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        var jwt = tokenHandler.WriteToken(token);

        // 3. Refresh Token Üretimi (Mock - Şifrelenmiş rastgele string)
        var refreshToken = Convert.ToBase64String(Guid.NewGuid().ToByteArray());

        return Ok(new TokenResponseDto
        {
            AccessToken = jwt,
            RefreshToken = refreshToken,
            Expiration = tokenDescriptor.Expires.Value
        });
    }
}