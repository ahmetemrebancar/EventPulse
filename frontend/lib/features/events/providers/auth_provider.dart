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

  // Çıkış Yapma Fonksiyonu
  void logout() {
    state = AuthState(); // State'i sıfırla
  }
}

// StateNotifierProvider yerine NotifierProvider kullanıyoruz
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});