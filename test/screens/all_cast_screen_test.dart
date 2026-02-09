import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/actor.dart';
import 'package:seriestime/screens/all_cast_screen.dart';

void main() {
  // Mock necessario per gestire Image.network nei test
  setUpAll(() => HttpOverrides.global = null);

  group('AllCastScreen Widget Tests', () {
    final mockCast = [
      Actor(
        name: "Bryan Cranston",
        characterName: "Walter White",
        profileUrl: null,
      ),
      Actor(
        name: "Aaron Paul",
        characterName: "Jesse Pinkman",
        profileUrl: null,
      ),
    ];

    testWidgets('Deve mostrare il titolo e la lista degli attori', (
      WidgetTester tester,
    ) async {
      // Carichiamo lo screen con dati finti
      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: mockCast, seriesName: "Breaking Bad"),
        ),
      );

      // 1. Verifica Titolo AppBar
      expect(find.text("Series Cast"), findsOneWidget);

      // 2. Verifica che i nomi degli attori siano visibili
      expect(find.text("Bryan Cranston"), findsOneWidget);
      expect(find.text("Aaron Paul"), findsOneWidget);

      // 3. Verifica i nomi dei personaggi
      expect(find.text("Walter White"), findsOneWidget);
      expect(find.text("Jesse Pinkman"), findsOneWidget);
    });

    testWidgets('Deve mostrare l\'icona person se il profileUrl è nullo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: [mockCast[0]], seriesName: "Test"),
        ),
      );

      // Verifica la presenza dell'icona di fallback
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Il tasto back deve essere presente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: mockCast, seriesName: "Test"),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
