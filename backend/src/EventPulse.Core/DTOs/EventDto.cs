namespace EventPulse.Core.DTOs;

public class EventDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public int MaxCapacity { get; set; }
    
    // Veritabanı Entity'sinde olmayan ama Frontend'in bilmesi gereken özel alan:
    public int CurrentAttendeesCount { get; set; } 
}