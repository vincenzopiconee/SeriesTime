import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/main.dart';
import 'package:seriestime/widgets/auth_gate.dart';

void main() {
  testWidgets('MyApp - Test Configurazione Iniziale e Temi', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('Firebase')) return;
      originalOnError?.call(details);
    };

    try {
      await tester.pumpWidget(const MyApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, equals('SeriesTime'));
      expect(app.debugShowCheckedModeBanner, isFalse);

      expect(app.theme?.useMaterial3, isTrue);

      expect(find.byType(AuthGate), findsOneWidget);

      await tester.pump();
    } finally {
      FlutterError.onError = originalOnError;
    }
  });
}
