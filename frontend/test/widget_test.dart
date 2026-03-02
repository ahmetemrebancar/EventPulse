import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Kendi ana dosyamızı import ediyoruz
// Not: Eğer proje adını 'event_pulse' yaptıysan import 'package:event_pulse/main.dart'; olarak kalabilir.
import 'package:event_pulse/main.dart'; 

void main() {
  testWidgets('EventPulse app smoke test', (WidgetTester tester) async {
    // Uygulamamızı Riverpod ProviderScope ile sarmalayarak başlatıyoruz
    await tester.pumpWidget(const ProviderScope(child: EventPulseApp()));

    // Uygulamanın çökmeden ayağa kalktığını ve MaterialApp içerdiğini doğrula
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}