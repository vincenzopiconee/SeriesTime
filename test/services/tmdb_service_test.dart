import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seriestime/services/tmdb_service.dart';

void main() {
  group('TmdbService - Unit Tests', () {
    test('fetchGenresForSeries deve restituire la lista corretta', () async {
      TmdbService.httpClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'genres': [
              {'name': 'Drama'},
              {'name': 'Sci-Fi'},
            ],
          }),
          200,
        );
      });

      final genres = await TmdbService.fetchGenresForSeries(123);
      expect(genres, containsAll(['Drama', 'Sci-Fi']));
    });

    test('fetchNextEpisode deve restituire NextEpisodeInfo', () async {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final airDateStr =
          "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";

      TmdbService.httpClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'next_episode_to_air': {
              'name': 'The Future Episode',
              'season_number': 1,
              'episode_number': 5,
              'air_date': airDateStr,
              'still_path': '/path.jpg',
            },
          }),
          200,
        );
      });

      final info = await TmdbService.fetchNextEpisode(123);
      expect(info, isNotNull);
      expect(info?.name, 'The Future Episode');
    });

    test(
      'fetchAndCalculateSeriesData deve gestire errori e tornare default',
      () async {
        TmdbService.httpClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final data = await TmdbService.fetchAndCalculateSeriesData(123);

        expect(data['seriesDuration'], 0.0);
        expect(data['averageRuntime'], 45);
      },
    );

    test(
      'fetchAndCalculateSeriesData deve coprire il ramo successo con poster e runtime',
      () async {
        TmdbService.httpClient = MockClient((request) async {
          return http.Response(
            json.encode({
              'poster_path': '/test_poster.jpg',
              'number_of_episodes': 20,
              'episode_run_time': [30],
            }),
            200,
          );
        });

        final data = await TmdbService.fetchAndCalculateSeriesData(123);

        expect(
          data['imageUrl'],
          contains('https://image.tmdb.org/t/p/w500/test_poster.jpg'),
        );
        expect(data['seriesDuration'], 10.0);
        expect(data['averageRuntime'], 30);
      },
    );

    test(
      'fetchAndCalculateSeriesData deve gestire poster_path nullo e runtime vuoto',
      () async {
        TmdbService.httpClient = MockClient((request) async {
          return http.Response(
            json.encode({
              'poster_path': null,
              'number_of_episodes': 10,
              'episode_run_time': [],
            }),
            200,
          );
        });

        final data = await TmdbService.fetchAndCalculateSeriesData(123);

        expect(data['imageUrl'], "");
        expect(data['averageRuntime'], 45);
        expect(data['seriesDuration'], 7.5);
      },
    );

    test(
      'getSeriesTotalRuntimeFromApi deve coprire ricerca e calcolo dettagli',
      () async {
        TmdbService.httpClient = MockClient((request) async {
          if (request.url.toString().contains('search/tv')) {
            return http.Response(
              json.encode({
                'results': [
                  {'id': 550},
                ],
              }),
              200,
            );
          }

          if (request.url.toString().contains('tv/550')) {
            return http.Response(
              json.encode({
                'number_of_episodes': 20,
                'episode_run_time': [45],
              }),
              200,
            );
          }

          return http.Response('Not Found', 404);
        });

        final runtime = await TmdbService.getSeriesTotalRuntimeFromApi(
          "Breaking Bad",
        );
        expect(runtime, 15.0);
      },
    );

    test(
      'getSeriesTotalRuntimeFromApi deve gestire lista risultati vuota',
      () async {
        TmdbService.httpClient = MockClient((request) async {
          return http.Response(json.encode({'results': []}), 200);
        });

        final runtime = await TmdbService.getSeriesTotalRuntimeFromApi(
          "SerieInesistente",
        );
        expect(runtime, 1.0);
      },
    );

    test(
      'getSeriesTotalRuntimeFromApi deve gestire runtime mancante usando il default di 45',
      () async {
        TmdbService.httpClient = MockClient((request) async {
          if (request.url.toString().contains('search/tv')) {
            return http.Response(
              json.encode({
                'results': [
                  {'id': 1},
                ],
              }),
              200,
            );
          }
          return http.Response(
            json.encode({'number_of_episodes': 10, 'episode_run_time': []}),
            200,
          );
        });

        final runtime = await TmdbService.getSeriesTotalRuntimeFromApi("Test");
        expect(runtime, 7.5);
      },
    );
  });
}
