namespace EventPulse.Core.Entities;

public class UserAttendance
{
    public string UserId { get; set; } = string.Empty;
    public int EventId { get; set; }
    public DateTime AttendedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    public Event? Event { get; set; }
}