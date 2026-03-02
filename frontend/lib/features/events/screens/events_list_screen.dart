import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/events_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/shimmer_loading_list.dart';
import 'event_detail_screen.dart';

// ConsumerStatefulWidget kullanıyoruz çünkü hem Riverpod'u (ref) dinleyeceğiz hem de kaydırma(scroll) hareketlerini takip edeceğiz.
class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Infinite Scroll (Sonsuz Kaydırma) Dinleyicisi
    _scrollController.addListener(() {
      // Eğer sayfanın en altına geldiysek, yeni veri yükleme fonksiyonunu tetikle
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(eventsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // eventsProvider'ın o anki durumunu (Loading, Error, Data) dinliyoruz
    final eventsState = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EventPulse', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // AsyncValue'nun gücü: Duruma göre otomatik UI değiştirme
      body: eventsState.when(
        // 1. Yükleniyor Durumu (Shimmer Efekti)
        loading: () => const ShimmerLoadingList(),
        
        // 2. Hata Durumu
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(eventsProvider.notifier).refresh(),
                child: const Text('Tekrar Dene'),
              )
            ],
          ),
        ),
        
        // 3. Başarılı Veri Durumu
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('Şu an hiç etkinlik bulunmuyor.'));
          }

          // Pull-to-refresh (Aşağı çekip yenileme) için RefreshIndicator
          return RefreshIndicator(
            onRefresh: () => ref.read(eventsProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: events.length + 1, // +1 ekliyoruz çünkü en altta loading dönebilir
              itemBuilder: (context, index) {
                if (index == events.length) {
                  // Listenin sonuna geldik, eğer hala yükleniyorsa altta spinner göster
                  return eventsState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink();
                }

                final event = events[index];
return EventCard(
                  event: event,
                  onTap: () {
                    //tODO ve print silindi, yerine gerçek yönlendirme eklendi!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(event: event),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}