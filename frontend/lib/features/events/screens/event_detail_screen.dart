import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:dio/dio.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';
import '../providers/auth_provider.dart';

// Yaşam döngüsünü (initState, dispose) kullanabilmek için ConsumerStatefulWidget
class EventDetailScreen extends ConsumerStatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late HubConnection _hubConnection;
  late int _currentAttendees;
  bool _isAttending = false; // İşlem sürerken butonu kilitlemek için

  @override
  void initState() {
    super.initState();
    // Başlangıçta sayıyı modelden alıyoruz
    _currentAttendees = widget.event.currentAttendeesCount;
    _initSignalR();
  }

  Future<void> _initSignalR() async {
    // ÖNEMLİ: Android Emülatör için 'http://10.0.2.2:5000/hub/events' kullanmalısın!
    // iOS veya Web için 'http://localhost:5000/hub/events'
    const hubUrl = 'http://10.0.2.2:5001/hub/events'; 

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .build();

    // Backend'den fırlatılan "ReceiveAttendeeUpdate" olayını dinliyoruz
    _hubConnection.on('ReceiveAttendeeUpdate', _handleAttendeeUpdate);

    try {
      await _hubConnection.start();
      if (_hubConnection.state == HubConnectionState.Connected) {
        // Backend'deki JoinEventGroup metodunu tetikleyip sadece bu etkinliğin odasına giriyoruz
        await _hubConnection.invoke('JoinEventGroup', args: [widget.event.id.toString()]);
      }
    } catch (e) {
      debugPrint('SignalR Bağlantı Hatası: $e');
    }
  }

  // Yeni sayı geldiğinde arayüzü tetikleyen fonksiyon
  void _handleAttendeeUpdate(List<Object?>? parameters) {
    if (parameters != null && parameters.length == 2) {
      final eventId = int.parse(parameters[0].toString());
      final newCount = int.parse(parameters[1].toString());

      if (eventId == widget.event.id) {
        setState(() {
          _currentAttendees = newCount;
        });
      }
    }
  }

  @override
  void dispose() {
    // Sayfa kapanırken odadan çık ve bağlantıyı kopar
    if (_hubConnection.state == HubConnectionState.Connected) {
      _hubConnection.invoke('LeaveEventGroup', args: [widget.event.id.toString()]).then((_) {
        _hubConnection.stop();
      });
    }
    super.dispose();
  }

  // API'ye Katılım İsteği Atan Fonksiyon
  Future<void> _attendEvent() async {
    setState(() => _isAttending = true);
    try {
      final dio = ref.read(dioProvider);
      // Şimdilik Auth yapmadığımız için test amaçlı statik bir userId gönderiyoruz
      await dio.post('/events/${widget.event.id}/attend', data: {
        'userId': ref.read(authProvider).username ?? 'Unknown'
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etkinliğe başarıyla katıldınız!'), backgroundColor: Colors.green),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data['message'] ?? 'Bir hata oluştu';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAttending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsyncValue = ref.watch(eventDetailProvider(widget.event.id));
    final isFull = _currentAttendees >= widget.event.maxCapacity;

    return Scaffold(
      appBar: AppBar(title: const Text('Etkinlik Detayı')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'event_title_${widget.event.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  widget.event.title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // CANLI GÜNCELLENEN KATILIMCI SAYISI
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFull ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                children: [
                  Icon(isFull ? Icons.group_off : Icons.group, color: isFull ? Colors.red : Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Canlı Katılımcı: $_currentAttendees / ${widget.event.maxCapacity}',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: isFull ? Colors.red : Colors.green
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Açıklama', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.event.description, style: const TextStyle(fontSize: 16, height: 1.5)),
            const Divider(height: 48),

            const Text('Yorumlar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            detailAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Yorumlar yüklenemedi: $err'),
              data: (detailData) {
                if (detailData.recentComments.isEmpty) {
                  return const Text('Henüz yorum yapılmamış. İlk yorumu sen yap!');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: detailData.recentComments.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(detailData.recentComments[index]),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80), 
          ],
        ),
      ),
      // Katıl Butonu
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_isAttending || isFull) ? null : _attendEvent,
        backgroundColor: isFull ? Colors.grey : Colors.deepPurple,
        icon: _isAttending 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(isFull ? Icons.block : Icons.check, color: Colors.white),
        label: Text(
          isFull ? 'Kapasite Dolu' : 'Katıl', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}