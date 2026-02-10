import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/main.dart';
import 'package:seriestime/widgets/auth_gate.dart';

void main() {
  testWidgets('MyApp - Test Configurazione Iniziale e Temi', (
    WidgetTester tester,
  ) async {
    // 1. Catturiamo gli errori di Firebase che scatteranno dentro AuthGate
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('Firebase')) return;
      originalOnError?.call(details);
    };

    try {
      // 2. Carichiamo l'intera applicazione
      await tester.pumpWidget(const MyApp());

      // 3. Verifichiamo che l'app sia stata creata con il titolo corretto
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, equals('SeriesTime'));
      expect(app.debugShowCheckedModeBanner, isFalse);

      // 4. Verifichiamo che il tema usi Material 3 (come impostato nel tuo codice)
      expect(app.theme?.useMaterial3, isTrue);

      // 5. Verifichiamo che la home iniziale sia l'AuthGate
      expect(find.byType(AuthGate), findsOneWidget);

      // 6. Facciamo un pump per coprire il builder del MediaQuery
      await tester.pump();
    } finally {
      FlutterError.onError = originalOnError;
    }
  });
}
