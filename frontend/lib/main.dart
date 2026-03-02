import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/screens/login_screen.dart'; // Bunu ekle

void main() {
  runApp(
    // Riverpod'un çalışması için zorunlu sarmalayıcı
    const ProviderScope(
      child: EventPulseApp(),
    ),
  );
}

class EventPulseApp extends StatelessWidget {
  const EventPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}