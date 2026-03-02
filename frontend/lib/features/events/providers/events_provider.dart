import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../models/event_detail_model.dart'; 
import 'auth_provider.dart'; 

// API İstekleri için Dio Sağlayıcısı
// ÖNEMLİ: Android Emülatör kullanıyorsan localhost yerine '10.0.2.2' kullanmalısın.
// iOS Simülatör veya Web kullanıyorsan 'localhost' kalabilir.
// API İstekleri için Dio Sağlayıcısı (Interceptor eklendi)
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:5000/api', // Emülatörde kullanmak için localhost yerine 10.0.2.2 konulması gerekir.
    connectTimeout: const Duration(seconds: 5),
  ));

  // Her istekten önce araya gir (Interceptor)
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // AuthProvider'dan mevcut token'ı oku
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        options.headers['Authorization'] = 'Bearer ${authState.token}';
      }
      return handler.next(options);
    },
  ));

  return dio;
});
// Vaka çalışmasının istediği AsyncNotifier yapısı 
class EventsNotifier extends AsyncNotifier<List<EventModel>> {
  int _page = 1;
  bool _hasMore = true; // Başka sayfa var mı kontrolü

  @override
  Future<List<EventModel>> build() async {
    _page = 1;
    _hasMore = true;
    return _fetchEventsPage(_page);
  }

  // Özel API Çağrısı Fonksiyonu
  Future<List<EventModel>> _fetchEventsPage(int page) async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/events', queryParameters: {
        'page': page,
        'pageSize': 10,
      });
      
      final List data = response.data;
      return data.map((e) => EventModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Etkinlikler yüklenemedi. Bağlantınızı kontrol edin.');
    }
  }

  // Infinite Scroll (Sonsuz Kaydırma) İçin Çağrılacak Metot 
  Future<void> loadMore() async {
    if (state.isLoading || !_hasMore) return;

    state = await AsyncValue.guard(() async {
      _page++;
      final newEvents = await _fetchEventsPage(_page);
      
      if (newEvents.isEmpty) {
        _hasMore = false; // Daha fazla veri kalmadı
      }
      
      // Eski veriyle yeni veriyi birleştir
      return [...?state.value, ...newEvents];
    });
  }

  // Pull-to-refresh (Yukarıdan çekip yenileme) İçin Çağrılacak Metot 
  Future<void> refresh() async {
    state = const AsyncLoading(); // Ekranı tekrar yükleme moduna al
    state = await AsyncValue.guard(() => build()); // İlk sayfayı tekrar çek
  }
}

// UI Tarafından Dinlenecek Global Provider
final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<EventModel>>(
  () => EventsNotifier(),
);

// Belirli bir etkinliğin detaylarını getiren FutureProvider
final eventDetailProvider = FutureProvider.family<EventDetailModel, int>((ref, id) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/events/$id');
  return EventDetailModel.fromJson(response.data);
});