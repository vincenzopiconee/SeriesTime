import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seriestime/services/series_logic.dart';
import 'package:seriestime/services/stats_logic.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http; 
import 'package:http/testing.dart'; 

void main() {
  group('SeriesLogic - Integration Tests', () {
    late FakeFirebaseFirestore fakeDb;
    const String testUid = 'user_123';

    setUp(() async {
      fakeDb = FakeFirebaseFirestore();
      SeriesLogic.db = fakeDb;
      StatsLogic.db = fakeDb;

      await fakeDb.collection('users').doc(testUid).set({
        'name': 'Test User',
        'seriesStreak': 0,
        'lastViewDate': null,
      });
    });

    test('isSeriesFavorite deve restituire il valore corretto', () async {
      final seriesName = "Dark";
      await fakeDb
          .collection('users')
          .doc(testUid)
          .collection('series')
          .doc(seriesName)
          .set({'isFavorite': true});

      final isFav = await SeriesLogic.isSeriesFavorite(
        seriesName,
        userUid: testUid,
      );
      expect(isFav, isTrue);

      final isNotFav = await SeriesLogic.isSeriesFavorite(
        "NonEsistente",
        userUid: testUid,
      );
      expect(isNotFav, isFalse);
    });

    test(
      'updateSeriesStreak deve incrementare lo streak se l ultima visione era ieri',
      () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));

        await fakeDb.collection('users').doc(testUid).update({
          'seriesStreak': 5,
          'lastViewDate': Timestamp.fromDate(yesterday),
        });

        await SeriesLogic.updateSeriesStreak(userUid: testUid);

        final doc = await fakeDb.collection('users').doc(testUid).get();
        expect(doc.data()?['seriesStreak'], 6);
      },
    );

    test(
      'updateSeriesStreak deve resettare lo streak se l ultima visione è troppo vecchia',
      () async {
        final longAgo = DateTime.now().subtract(const Duration(days: 5));

        await fakeDb.collection('users').doc(testUid).update({
          'seriesStreak': 10,
          'lastViewDate': Timestamp.fromDate(longAgo),
        });

        await SeriesLogic.updateSeriesStreak(userUid: testUid);

        final doc = await fakeDb.collection('users').doc(testUid).get();
        expect(doc.data()?['seriesStreak'], 1);
      },
    );

    test(
      'toggleEpisodeWatched deve salvare correttamente i dati dell episodio',
      () async {
        final String seriesName = "Breaking Bad";

        await SeriesLogic.toggleEpisodeWatched(
          seriesName: seriesName,
          seriesId: 1396,
          seasonNum: 1,
          episodeNum: 1,
          episodeTitle: "Pilot",
          isWatched: true,
          userUid: testUid,
        );

        final epDoc = await fakeDb
            .collection('users')
            .doc(testUid)
            .collection('series')
            .doc(seriesName)
            .collection('seasons')
            .doc('Season 1')
            .collection('episodes')
            .doc('Episode 1')
            .get();

        expect(epDoc.exists, isTrue);
        expect(epDoc.data()?['watched'], isTrue);
        expect(epDoc.data()?['episode_title'], "Pilot");
      },
    );
    test(
      'syncSeriesTotalHours deve passare alla stagione successiva se la corrente è finita',
      () async {
        final String seriesName = "The Boys";
        final int seriesId = 76479;

        final seriesRef = fakeDb
            .collection('users')
            .doc(testUid)
            .collection('series')
            .doc(seriesName);
        await seriesRef.set({'id': seriesId});

        final seasonRef = seriesRef.collection('seasons').doc('Season 1');
        await seasonRef.set({'season_number': 1});
        await seasonRef.collection('episodes').doc('Episode 8').set({
          'episode_number': 8,
          'season_number': 1,
          'watched': true,
          'runtime': 60,
        });

        SeriesLogic.httpClient = MockClient((request) async {
          if (request.url.toString().contains('season/1')) {
            return http.Response(
              json.encode({
                'episodes': [
                  {'episode_number': 8},
                ], 
              }),
              200,
            );
          }
          if (request.url.toString().contains('season/2')) {
            return http.Response(
              json.encode({
                'episodes': [
                  {
                    'episode_number': 1,
                    'season_number': 2,
                    'name': 'Next Gen',
                    'air_date': '2024-01-01',
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('', 404);
        });

        await SeriesLogic.syncSeriesTotalHours(seriesName, userUid: testUid);

        final updatedDoc = await seriesRef.get();
        expect(updatedDoc.data()?['episode'], "S2 E1");
        expect(updatedDoc.data()?['completed'], isFalse);
      },
    );

    test(
      'syncSeriesTotalHours deve gestire errore API e completare la serie',
      () async {
        final String seriesName = "SeriesFinita";
        final seriesRef = fakeDb
            .collection('users')
            .doc(testUid)
            .collection('series')
            .doc(seriesName);
        await seriesRef.set({'id': 999});

        final seasonRef = seriesRef.collection('seasons').doc('Season 1');
        await seasonRef.set({'season_number': 1});
        await seasonRef.collection('episodes').doc('Episode 1').set({
          'episode_number': 1,
          'watched': true,
          'runtime': 30,
        });

        SeriesLogic.httpClient = MockClient((request) async {
          if (request.url.toString().contains('season/1')) {
            return http.Response(
              json.encode({
                'episodes': [
                  {'episode_number': 1},
                ],
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        await SeriesLogic.syncSeriesTotalHours(seriesName, userUid: testUid);

        final updatedDoc = await seriesRef.get();
        expect(updatedDoc.data()?['completed'], isTrue);
      },
    );

    test(
      'syncSeriesTotalHours deve entrare nel catch in caso di JSON malformato',
      () async {
        final String seriesName = "ErrorSeries";
        await fakeDb
            .collection('users')
            .doc(testUid)
            .collection('series')
            .doc(seriesName)
            .set({'id': 123});

        SeriesLogic.httpClient = MockClient((request) async {
          return http.Response('Dati Corrotti non JSON', 200);
        });

        await SeriesLogic.syncSeriesTotalHours(seriesName, userUid: testUid);

        expect(true, isTrue);
      },
    );
    test(
      'toggleEpisodeWatched deve usare averageRuntime esistente se presente',
      () async {
        final String seriesName = "ExistingSeries";
        final seriesRef = fakeDb
            .collection('users')
            .doc(testUid)
            .collection('series')
            .doc(seriesName);

        await seriesRef.set({'id': 123, 'averageRuntime': 22});

        await SeriesLogic.toggleEpisodeWatched(
          seriesName: seriesName,
          seriesId: 123,
          seasonNum: 1,
          episodeNum: 1,
          episodeTitle: "Pilot",
          isWatched: true,
          userUid: testUid,
        );

        final epDoc = await seriesRef
            .collection('seasons')
            .doc('Season 1')
            .collection('episodes')
            .doc('Episode 1')
            .get();

        expect(epDoc.data()?['runtime'], 22);
      },
    );
    test(
      'toggleEpisodeWatched deve recuperare averageRuntime se mancante nel doc serie',
      () async {
        final String seriesName = "MissingRuntimeSeries";
        final seriesRef = fakeDb
            .collection('users')
            .doc(testUid)
            .collection('series')
            .doc(seriesName);

        await seriesRef.set({'id': 456, 'imageUrl': 'test.jpg'});

        await SeriesLogic.toggleEpisodeWatched(
          seriesName: seriesName,
          seriesId: 456,
          seasonNum: 1,
          episodeNum: 2,
          episodeTitle: "Ep 2",
          isWatched: true,
          userUid: testUid,
        );

        final updatedSeries = await seriesRef.get();
        expect(updatedSeries.data()!.containsKey('averageRuntime'), isTrue);
      },
    );
    test(
      'updateGenreCount deve contare i generi unici delle serie iniziate',
      () async {
        final seriesName = "GenreTestSeries";

        await fakeDb
            .collection('users')
            .doc(testUid)
            .collection('series')
            .doc(seriesName)
            .set({
              'id': 1396, 
              'percentage': 0.5, 
            });

        await SeriesLogic.updateGenreCount(userUid: testUid);

        final userDoc = await fakeDb.collection('users').doc(testUid).get();

        expect(userDoc.data()!.containsKey('uniqueGenresCount'), isTrue);
      },
    );
  });
}
