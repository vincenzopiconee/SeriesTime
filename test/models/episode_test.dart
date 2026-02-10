import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/episode.dart';

void main() {
  group('Episode Model Tests', () {
    test('Creazione Episode tramite costruttore standard', () {
      final episode = Episode(
        id: 101,
        name: "Pilot",
        episodeNumber: 1,
        overview: "L'inizio di tutto.",
        runtime: 45,
        voteAverage: 8.5,
      );

      expect(episode.id, 101);
      expect(episode.name, "Pilot");
      expect(episode.guestStars, isEmpty);
    });

    test(
      'Episode.fromJson deve mappare correttamente i dati TMDB e le Guest Stars',
      () {
        // Mock JSON in formato TMDB
        final Map<String, dynamic> json = {
          'id': 12345,
          'name': 'The Box',
          'episode_number': 5,
          'overview': 'Un episodio intenso.',
          'still_path': '/path_immagine.jpg',
          'runtime': 42,
          'vote_average': 9.2,
          'guest_stars': [
            {
              'name': 'Actor One',
              'character': 'Character One',
              'profile_path': '/p1.jpg',
            },
            {
              'name': 'Actor Two',
              'character': 'Character Two',
              'profile_path': null,
            },
          ],
        };

        final episode = Episode.fromJson(json);

        expect(episode.id, 12345);
        expect(episode.episodeNumber, 5);
        expect(episode.runtime, 42);
        expect(episode.voteAverage, 9.2);
        // Verifica costruzione URL immagine
        expect(
          episode.stillUrl,
          'https://image.tmdb.org/t/p/w500/path_immagine.jpg',
        );

        // Verifica Guest Stars (Integrazione con Actor)
        expect(episode.guestStars.length, 2);
        expect(episode.guestStars[0].name, 'Actor One');
        expect(episode.guestStars[1].profileUrl, isNull);
      },
    );

    test('Episode.fromJson deve gestire campi mancanti o nulli', () {
      final Map<String, dynamic> json = {
        'id': 999,
        'episode_number': 10,
        // name, overview, guest_stars, runtime sono assenti
      };

      final episode = Episode.fromJson(json);

      expect(episode.id, 999);
      // Fallback: name diventa "Episode 10" se null
      expect(episode.name, "Episode 10");
      expect(episode.overview, "");
      expect(episode.runtime, 0);
      expect(episode.guestStars, isEmpty);
    });
  });
}
