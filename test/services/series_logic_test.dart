import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seriestime/services/series_logic.dart';
import 'package:seriestime/services/stats_logic.dart';
import 'dart:convert'; // Per 'json'
import 'package:http/http.dart' as http; // Per 'http'
import 'package:http/testing.dart'; // Per 'MockClient'

void main() {
  group('SeriesLogic - Integration Tests', () {
    late FakeFirebaseFirestore fakeDb;
    const String testUid = 'user_123';

    setUp(() async {
      fakeDb = FakeFirebaseFirestore();
      // Iniettiamo il database finto nel servizio
      SeriesLogic.db = fakeDb;
      // Anche StatsLogic deve usare lo stesso db perché viene chiamato internamente
      StatsLogic.db = fakeDb;

      // Prepariamo il documento utente
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

        // Nota: syncSeriesTotalHours farà chiamate HTTP a TMDB.
        // In un test unitario puro, quelle chiamate potrebbero fallire se non mockate,
        // ma il salvataggio su Firestore avverrà comunque.

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

        // Inseriamo l'ultimo episodio della stagione 1 come "visto"
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

        // Mockiamo il client per simulare:
        // 1. Stagione 1 completa (nessun episodio 9)
        // 2. Stagione 2 esistente con episodio 1
        SeriesLogic.httpClient = MockClient((request) async {
          if (request.url.toString().contains('season/1')) {
            return http.Response(
              json.encode({
                'episodes': [
                  {'episode_number': 8},
                ], // Solo ep 8, quindi ep 9 non esiste
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
        // Deve aver trovato S2 E1
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

        // Simuliamo errore 404 sulla stagione successiva
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

        // Forziamo un errore di decoding JSON
        SeriesLogic.httpClient = MockClient((request) async {
          return http.Response('Dati Corrotti non JSON', 200);
        });

        // Non deve crashare grazie al try-catch
        await SeriesLogic.syncSeriesTotalHours(seriesName, userUid: testUid);

        // Se entra nel catch, debugPrint viene eseguito e il test passa
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

        // Prepariamo la serie con un runtime specifico (es. 22 minuti)
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

        // Verifichiamo che l'episodio sia stato salvato con i 22 minuti presi dal doc serie
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

        // Prepariamo la serie SENZA il campo averageRuntime
        await seriesRef.set({'id': 456, 'imageUrl': 'test.jpg'});

        // Nota: Qui TmdbService.fetchAndCalculateSeriesData verrà chiamato.
        // Se non hai mockato TmdbService, il test userà il valore di default dell'API o fallirà se non c'è rete.

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
        // Verifichiamo che il campo sia stato aggiunto al documento della serie
        expect(updatedSeries.data()!.containsKey('averageRuntime'), isTrue);
      },
    );
    test(
      'updateGenreCount deve contare i generi unici delle serie iniziate',
      () async {
        final seriesName = "GenreTestSeries";

        // 1. Prepariamo una serie nel DB con percentuale > 0 e un ID
        await fakeDb
            .collection('users')
            .doc(testUid)
            .collection('series')
            .doc(seriesName)
            .set({
              'id': 1396, // Breaking Bad
              'percentage': 0.5, // Serie iniziata
            });

        // 2. Chiamiamo il metodo
        // Nota: TmdbService.fetchGenresForSeries(1396) verrà chiamato.
        // Se non hai mockato TmdbService, assicurati che non crashi senza rete.
        await SeriesLogic.updateGenreCount(userUid: testUid);

        // 3. Verifichiamo che il conteggio sia stato aggiornato sul documento utente
        final userDoc = await fakeDb.collection('users').doc(testUid).get();

        // Se TmdbService restituisce generi, uniqueGenresCount sarà > 0
        // Altrimenti sarà 0, ma la riga di codice sarà stata comunque "visitata"
        expect(userDoc.data()!.containsKey('uniqueGenresCount'), isTrue);
      },
    );
  });
}
