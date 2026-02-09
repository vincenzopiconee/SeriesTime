import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/tv_show_details.dart';

void main() {
  group('TvShowDetails Model Tests', () {
    test(
      'TvShowDetails.fromJson deve mappare correttamente un JSON completo di TMDB',
      () {
        final Map<String, dynamic> json = {
          'id': 1399,
          'name': 'Game of Thrones',
          'poster_path': '/poster.jpg',
          'backdrop_path': '/backdrop.jpg',
          'overview': 'Scontro tra famiglie nobili.',
          'vote_average': 8.4,
          'vote_count': 21000,
          'status': 'Ended',
          'number_of_seasons': 8,
          'number_of_episodes': 73,
          'genres': [
            {'name': 'Drama'},
            {'name': 'Fantasy'},
          ],
          'networks': [
            {'name': 'HBO'},
          ],
          'created_by': [
            {'name': 'David Benioff'},
            {'name': 'D.B. Weiss'},
          ],
          'seasons': [
            {
              'id': 1,
              'season_number': 0,
              'episode_count': 10,
            }, // Speciale (dovrebbe essere filtrata)
            {'id': 2, 'season_number': 1, 'episode_count': 10},
          ],
          'aggregate_credits': {
            'cast': [
              {
                'name': 'Emilia Clarke',
                'profile_path': '/emilia.jpg',
                'roles': [
                  {'character': 'Daenerys Targaryen'},
                ],
              },
              {
                'name': 'Kit Harington',
                'roles': [
                  {'character': 'Jon Snow'},
                  {'character': 'Aegon Targaryen'},
                ],
              },
            ],
          },
          'watch/providers': {
            'results': {
              'US': {
                'flatrate': [
                  {
                    'provider_name': 'Max',
                    'logo_path': '/max.jpg',
                    'provider_id': 1,
                  },
                ],
              },
            },
          },
          'last_episode_to_air': {
            'name': 'The Iron Throne',
            'season_number': 8,
            'episode_number': 6,
            'air_date': '2019-05-19',
          },
        };

        final details = TvShowDetails.fromJson(json);

        expect(details.name, 'Game of Thrones');
        expect(details.genres, contains('Fantasy'));

        // Verifica filtro stagioni (seasonNumber > 0)
        expect(details.seasons.length, 1);
        expect(details.seasons[0].seasonNumber, 1);

        // Verifica logica nomi cast (multi-ruolo)
        expect(details.cast[0].characterName, 'Daenerys Targaryen');
        expect(
          details.cast[1].characterName,
          'Jon Snow (+1)',
        ); // Verifica il "+1"

        // Verifica providers e ultimo episodio
        expect(details.watchProviders.length, 1);
        expect(details.lastEpisode?.name, 'The Iron Throne');
      },
    );

    test(
      'TvShowDetails.fromJson deve gestire i campi mancanti graziosamente',
      () {
        final Map<String, dynamic> json = {
          'id': 0,
          'name': null,
          // Molti campi assenti
        };

        final details = TvShowDetails.fromJson(json);

        expect(details.name, 'Untitled');
        expect(details.overview, "");
        expect(details.genres, isEmpty);
        expect(details.cast, isEmpty);
        expect(details.seasons, isEmpty);
      },
    );
  });
}
