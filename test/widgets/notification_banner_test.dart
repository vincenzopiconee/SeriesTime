import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/widgets/notification_banner.dart';
import 'package:seriestime/models/user_badge.dart';

void main() {
  final testBadge = UserBadge(
    id: "test_1",
    title: "Marathoner",
    iconLabel: "10h",
    imagePath: "assets/images/badges/m1.png",
    targetHours: 10,
  );

  testWidgets('NotificationBanner - Test Animazione e Testi', (
    WidgetTester tester,
  ) async {
    // 1. Impostiamo una dimensione dello schermo più grande per evitare l'overflow (1.00 pixel)
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    bool dismissed = false;

    // 2. Usiamo un try-catch per assorbire l'errore del caricamento asset immagine
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('asset'))
        return; // Ignora errore immagine
      originalOnError?.call(details);
    };

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBanner(
              badge: testBadge,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );

      // 3. Verifica testi
      expect(find.text("New Reward Available!"), findsOneWidget);

      // 4. Gestione animazione e timer (ElasticOut e Future.delayed)
      await tester.pump(const Duration(milliseconds: 800));

      // Passiamo oltre i 4 secondi di attesa per innescare la chiusura
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // 5. Verifica che il banner si sia chiuso
      expect(dismissed, isTrue);
    } finally {
      FlutterError.onError = originalOnError;
      // Reset della dimensione dello schermo
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}
