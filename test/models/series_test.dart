import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/series.dart';

void main() {
  group('Series Model Tests', () {
    test('Creazione Series e verifica valori iniziali', () {
      final series = Series(
        id: 1,
        name: "Breaking Bad",
        imageUrl: "https://image.tmdb.org/t/p/w500/path.jpg",
        percentage: 0.5,
        totalHours: 25.5,
        episode: "S3 E5",
        seriesDuration: 50.0,
        isFavorite: true,
      );

      expect(series.id, 1);
      expect(series.name, "Breaking Bad");
      expect(series.percentage, 0.5);
      expect(series.totalHours, 25.5);
      expect(series.isFavorite, isTrue);
      expect(series.completed, isFalse); // Default value
    });

    test(
      'Il getter timeLabel deve formattare correttamente la stringa delle ore',
      () {
        final series = Series(
          id: 2,
          name: "The Bear",
          imageUrl: "",
          percentage: 1.0,
          totalHours: 12.0,
          episode: "S2 E8",
        );

        // Verifica che aggiunga la 'h' alla fine del numero
        expect(series.timeLabel, "12.0h");
      },
    );

    test('Modifica dei campi mutabili (totalHours e isFavorite)', () {
      final series = Series(
        id: 3,
        name: "Dark",
        imageUrl: "",
        percentage: 0.1,
        totalHours: 1.0,
        episode: "S1 E1",
      );

      // Simuliamo l'aggiornamento dei dati (es. l'utente guarda altri episodi)
      series.totalHours = 5.0;
      series.isFavorite = true;

      expect(series.totalHours, 5.0);
      expect(series.isFavorite, isTrue);
    });

    test('Verifica della lista watchedEpisodes', () {
      final series = Series(
        id: 4,
        name: "Succession",
        imageUrl: "",
        percentage: 0.2,
        totalHours: 2.0,
        episode: "S1 E2",
        watchedEpisodes: [
          {'season': 1, 'episode': 1},
          {'season': 1, 'episode': 2},
        ],
      );

      expect(series.watchedEpisodes.length, 2);
      expect(series.watchedEpisodes[0]['episode'], 1);
    });
  });
}
