namespace EventPulse.Core.Entities;

public class Comment
{
    public int Id { get; set; }
    public int EventId { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty; 
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    public Event? Event { get; set; }
}