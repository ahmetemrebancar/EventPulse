namespace EventPulse.Core.Entities;

public class Event
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public int MaxCapacity { get; set; } // MaxCapacity > 0 kısıtı eklenecek 
    
    // Navigation Properties
    public ICollection<UserAttendance> Attendances { get; set; } = new List<UserAttendance>();
    public ICollection<Comment> Comments { get; set; } = new List<Comment>();
}