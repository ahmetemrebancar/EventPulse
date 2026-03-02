using Microsoft.AspNetCore.SignalR;

namespace EventPulse.API.Hubs;

public class EventHub : Hub
{
    // İstemciler (Flutter) bağlandığında özel bir etkinlik odasına (grubuna) katılmalarını sağlayacağız
    public async Task JoinEventGroup(string eventId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Event_{eventId}");
    }

    public async Task LeaveEventGroup(string eventId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Event_{eventId}");
    }
}