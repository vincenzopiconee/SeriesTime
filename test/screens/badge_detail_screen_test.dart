import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/user_badge.dart';
import 'package:seriestime/screens/badge_detail_screen.dart';

void main() {
  group('BadgeDetailScreen Widget Tests', () {
    final mockMilestones = [
      UserBadge(
        id: "mbase",
        title: "Marathoner",
        imagePath: "assets/images/marathoner_base.png",
        iconLabel: "1d",
        targetHours: 24,
      ),
    ];

    testWidgets('Deve mostrare i testi corretti per la categoria Marathoner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: "Marathoner",
            milestones: mockMilestones,
            currentValue: 10.5,
            unit: "h",
          ),
        ),
      );

      // 1. Verifica Titolo nell'AppBar
      expect(find.text("Marathoner"), findsOneWidget);

      // 2. Verifica la formattazione del valore (10.5h -> 10h 30m)
      // La tua logica: int h = 10, int m = (0.5 * 60) = 30
      expect(find.text("10h 30m"), findsOneWidget);

      // 3. Verifica la descrizione specifica
      expect(
        find.textContaining("tracks your total lifetime watch time"),
        findsOneWidget,
      );
    });

    testWidgets(
      'Deve formattare correttamente i valori per Genre Explorer (G)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BadgeDetailScreen(
              categoryTitle: "Genre Explorer",
              milestones: mockMilestones,
              currentValue: 5.0,
              unit: "G",
            ),
          ),
        );

        expect(find.text("5 Genres"), findsOneWidget);
        expect(find.textContaining("Measures your curiosity"), findsOneWidget);
      },
    );

    testWidgets('Deve mostrare la sezione Mission Milestones', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: "Streak",
            milestones: mockMilestones,
            currentValue: 7.0,
            unit: "d",
          ),
        ),
      );

      expect(find.text("Mission Milestones"), findsOneWidget);
      // Verifica la label del livello all'interno della lista
      expect(find.text("Level: 1d"), findsOneWidget);
    });

    testWidgets('Verifica formattazione giorni e ore (dh)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: "Custom",
            milestones: mockMilestones,
            currentValue: 26.0, // 1 giorno e 2 ore
            unit: "dh",
          ),
        ),
      );

      expect(find.text("1d 2h"), findsOneWidget);
    });
  });
}
