import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/season.dart';

void main() {
  group('Season Model Tests', () {
    test('Creazione Season tramite costruttore standard', () {
      final season = Season(
        id: 1,
        name: "Stagione 1",
        seasonNumber: 1,
        episodeCount: 10,
      );

      expect(season.id, 1);
      expect(season.name, "Stagione 1");
      expect(season.episodeCount, 10);
    });

    test('Season.fromJson deve mappare correttamente i dati TMDB', () {
      final Map<String, dynamic> json = {
        'id': 123,
        'name': 'Specials',
        'season_number': 0,
        'episode_count': 5,
      };

      final season = Season.fromJson(json);

      expect(season.id, 123);
      expect(season.name, 'Specials');
      expect(season.seasonNumber, 0);
      expect(season.episodeCount, 5);
    });

    test(
      'Season.fromJson deve generare un nome di fallback se il nome è nullo',
      () {
        final Map<String, dynamic> json = {
          'id': 456,
          'name': null,
          'season_number': 2,
          'episode_count': 13,
        };

        final season = Season.fromJson(json);

        expect(season.name, "Season 2");
      },
    );

    test(
      'Season.fromJson deve gestire i valori numerici nulli con i default',
      () {
        final Map<String, dynamic> json = {
          'id': 789,
          'name': 'Test Season',
          'season_number': null,
          'episode_count': null,
        };

        final season = Season.fromJson(json);

        expect(season.seasonNumber, 0);
        expect(season.episodeCount, 0);
      },
    );
  });
}
