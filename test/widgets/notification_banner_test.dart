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
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    bool dismissed = false;

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('asset')) return;
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

      expect(find.text("New Reward Available!"), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 800));

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    } finally {
      FlutterError.onError = originalOnError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}
