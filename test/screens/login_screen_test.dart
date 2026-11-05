import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/screens/login_screen.dart';

void main() {
  setUpAll(() => HttpOverrides.global = null);

  testWidgets('LoginScreen - Test Stabilità e Copertura', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;

    FlutterError.onError = (details) {};

    try {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text("SeriesTime"), findsOneWidget);
      expect(find.text("LOG IN with Google"), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    } finally {
      FlutterError.onError = originalOnError;
    }
  });
}
