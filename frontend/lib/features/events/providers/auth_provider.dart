import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

// Sadece token'ı ve kullanıcı adını tutacağımız basit bir state sınıfı
class AuthState {
  final String? token;
  final String? username;

  AuthState({this.token, this.username});
  bool get isAuthenticated => token != null;
}

// StateNotifier yerine modern Notifier kullanıyoruz
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(); // Başlangıç state'i (Boş)
  }

  // Giriş Yapma Fonksiyonu
  Future<bool> login(String username, String password, Dio dio) async {
    try {
      final response = await dio.post('/auth/token', data: {
        'username': username,
        'password': password,
      });
      
      final token = response.data['accessToken'];
      
      // Token'ı ve kullanıcı adını state'e kaydet
      state = AuthState(token: token, username: username);
      return true;
    } catch (e) {
      return false; // Hata veya yanlış şifre
    }
  }

    Future<void> logout() async {
  // 1. Kaydedilmiş JWT token'ını sil (Örnek: SharedPreferences kullanıyorsan)
  // final prefs = await SharedPreferences.getInstance();
  // await prefs.remove('jwt_token');

  // 2. State'i temizle (Başlangıçtaki boş duruma geri dön)
    state = AuthState(); 
}
}

// StateNotifierProvider yerine NotifierProvider kullanıyoruz
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});