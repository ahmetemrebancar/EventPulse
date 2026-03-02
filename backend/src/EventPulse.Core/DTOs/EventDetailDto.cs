namespace EventPulse.Core.DTOs;

public class EventDetailDto : EventDto
{
    // EventDto'daki tüm özellikleri miras alır (Title, City vb.)
    // Üzerine detay sayfasında gerekecek ekstra alanları ekliyoruz:
    
    public int CommentsCount { get; set; }
    public List<string> RecentComments { get; set; } = new();
}

