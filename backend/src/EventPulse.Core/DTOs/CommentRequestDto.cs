using System.ComponentModel.DataAnnotations;

namespace EventPulse.Core.DTOs;

public class CommentRequestDto
{
    public string UserId { get; set; } = string.Empty;

    [Required(ErrorMessage = "Yorum içeriği boş olamaz.")]
    [MaxLength(500, ErrorMessage = "Yorum en fazla 500 karakter olabilir.")]
    public string Content { get; set; } = string.Empty;
}