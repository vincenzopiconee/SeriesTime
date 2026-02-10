import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/next_episode_info.dart';

void main() {
  group('NextEpisodeInfo Model Tests', () {
    test('Creazione NextEpisodeInfo e integrità dati', () {
      final airDate = DateTime(2025, 12, 25);
      final nextEp = NextEpisodeInfo(
        name: "Special Christmas",
        episodeLabel: "S1 E10",
        airDate: airDate,
        stillUrl: "https://image.tmdb.org/t/p/w500/path.jpg",
      );

      expect(nextEp.name, "Special Christmas");
      expect(nextEp.episodeLabel, "S1 E10");
      expect(nextEp.airDate, airDate);
      expect(nextEp.stillUrl, contains("/path.jpg"));
    });

    test(
      'Il getter daysLeft deve calcolare correttamente i giorni mancanti',
      () {
        final now = DateTime.now();
        final futureDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 5));

        final nextEp = NextEpisodeInfo(
          name: "Future Episode",
          episodeLabel: "S2 E1",
          airDate: futureDate,
        );

        expect(nextEp.daysLeft, 5);
      },
    );

    test('daysLeft deve restituire 0 se l\'episodio esce oggi', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final nextEp = NextEpisodeInfo(
        name: "Today Episode",
        episodeLabel: "S1 E1",
        airDate: today,
      );

      expect(nextEp.daysLeft, 0);
    });

    test(
      'daysLeft deve restituire un valore negativo se l\'episodio è già uscito',
      () {
        final pastDate = DateTime(2020, 1, 1);

        final nextEp = NextEpisodeInfo(
          name: "Past Episode",
          episodeLabel: "S1 E1",
          airDate: pastDate,
        );

        expect(nextEp.daysLeft, lessThan(0));
      },
    );
  });
}
