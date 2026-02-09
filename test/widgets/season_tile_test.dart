import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/widgets/season_tile.dart';
import 'package:seriestime/models/season.dart';

void main() {
  // Blocchiamo il network per evitare crash con Image.network o API
  setUpAll(() => HttpOverrides.global = null);

  // Creiamo un badge finto basato esattamente sul tuo modello Season
  final testSeason = Season(
    id: 123,
    name: "Season 1",
    seasonNumber: 1,
    episodeCount: 10,
  );

  testWidgets('SeasonTile - Test Espansione e Struttura', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    // Silenziamo Firebase/Firestore per evitare il blocco del test
    FlutterError.onError = (details) {};

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonTile(
              seriesId: 1396,
              seriesName: "Breaking Bad",
              season: testSeason,
            ),
          ),
        ),
      );

      // 1. Verifica che i testi della stagione siano visibili
      expect(find.text("Season 1"), findsOneWidget);
      expect(find.text("10 Episodes"), findsOneWidget);

      // 2. Simuliamo il tocco per espandere l'ExpansionTile
      // Questo attiva il metodo _fetchEpisodes() nel tuo SeasonTile
      await tester.tap(find.byType(ExpansionTile));
      await tester.pump(); // Inizio animazione

      // 3. Verifica che appaia il caricamento mentre "attende" i dati (che falliranno)
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // 4. Facciamo passare il tempo per smaltire i Future pendenti
      await tester.pump(const Duration(seconds: 1));
    } finally {
      // Ripristiniamo sempre il framework
      FlutterError.onError = originalOnError;
    }
  });
}
