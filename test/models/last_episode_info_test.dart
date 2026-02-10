import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/last_episode_info.dart';

void main() {
  group('LastEpisodeInfo Model Tests', () {
    test('Creazione LastEpisodeInfo tramite costruttore standard', () {
      final lastEp = LastEpisodeInfo(
        name: "Felina",
        seasonNumber: 5,
        episodeNumber: 16,
        airDate: "2013-09-29",
      );

      expect(lastEp.name, "Felina");
      expect(lastEp.seasonNumber, 5);
      expect(lastEp.episodeNumber, 16);
      expect(lastEp.airDate, "2013-09-29");
    });

    test('LastEpisodeInfo.fromJson deve mappare correttamente i dati TMDB', () {
      final Map<String, dynamic> json = {
        'name': 'The Iron Throne',
        'season_number': 8,
        'episode_number': 6,
        'air_date': '2019-05-19',
      };

      final lastEp = LastEpisodeInfo.fromJson(json);

      expect(lastEp.name, 'The Iron Throne');
      expect(lastEp.seasonNumber, 8);
      expect(lastEp.episodeNumber, 6);
      expect(lastEp.airDate, '2019-05-19');
    });

    test(
      'LastEpisodeInfo.fromJson deve gestire i valori null o mancanti con i fallback',
      () {
        final Map<String, dynamic> json = {
          'name': null,
          'season_number': null,
          'episode_number': null,
          'air_date': null,
        };

        final lastEp = LastEpisodeInfo.fromJson(json);

        // Verifichiamo che scattino i default impostati nel factory
        expect(lastEp.name, "Unknown Episode");
        expect(lastEp.seasonNumber, 0);
        expect(lastEp.episodeNumber, 0);
        expect(lastEp.airDate, "N/A");
      },
    );
  });
}
