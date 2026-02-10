import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:seriestime/services/tmdb_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late MockFirebaseAuth fakeAuth;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    fakeAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'test_uid',
        displayName: 'Test User',
        photoURL: 'http://googleusercontent.com/profile/picture/s96-c/0',
      ),
    );

    AppData.db = fakeDb;
    AppData.firebaseAuth = fakeAuth;
    AppData.resetData();

    TmdbService.mockSeriesData = null;
  });

  group('AppData Logic Tests', () {
    test(
      'initializeData deve popolare il profilo al primo accesso e gestire URL foto Google',
      () async {
        await AppData.initializeData();

        final userDoc = await fakeDb.collection('users').doc('test_uid').get();
        expect(userDoc.exists, isTrue);
        expect(AppData.currentUser?.photoUrl, contains('s400-c'));
      },
    );

    test(
      'initializeData deve caricare correttamente le serie esistenti (senza crash)',
      () async {
        await fakeDb
            .collection('users')
            .doc('test_uid')
            .collection('series')
            .doc('Breaking Bad')
            .set({
              'id': 1396,
              'imageUrl': 'http://image.jpg',
              'percentage': 50.0,
              'totalHours': 20.5,
              'episode': 'S1 E1',
              'lastEpisodeTitle': 'Pilot',
              'nextEpisodeAirDate': null,
              'seriesDuration': 60.0,
              'isFavorite': true,
              'completed': false,
            });

        await AppData.initializeData();

        expect(AppData.userSeries.length, 1);
        expect(AppData.userSeries.first.name, 'Breaking Bad');
        expect(AppData.userSeries.first.totalHours, 20.5);
      },
    );

    test('getTotalWatchTimeSplit calcola correttamente i tempi', () async {
      await fakeDb
          .collection('users')
          .doc('test_uid')
          .collection('series')
          .doc('Show1')
          .set({
            'id': 1,
            'totalHours': 26.5,
            'imageUrl': '',
            'episode': '',
            'lastEpisodeTitle': '',
            'isFavorite': false,
            'completed': false,
          });

      await AppData.initializeData();
      final split = AppData.getTotalWatchTimeSplit();

      expect(split['days'], 1);
      expect(split['hours'], 2);
      expect(split['minutes'], 30);
    });

    test(
      'setSeriesFavorite crea nuova serie se non esiste usando mock TMDB',
      () async {
        TmdbService.mockSeriesData = {
          'imageUrl': 'http://image.jpg',
          'seriesDuration': 100.0,
          'averageRuntime': 45,
        };

        await AppData.initializeData();

        await AppData.setSeriesFavorite('New Series', 999, true);

        final seriesDoc = await fakeDb
            .collection('users')
            .doc('test_uid')
            .collection('series')
            .doc('New Series')
            .get();
        expect(seriesDoc.exists, isTrue);
        expect(seriesDoc.data()!['id'], 999);
        expect(AppData.userSeries.any((s) => s.name == 'New Series'), isTrue);
      },
    );

    test(
      'setSeriesFavorite rimuove serie se favorite è false e ore sono 0',
      () async {
        await fakeDb
            .collection('users')
            .doc('test_uid')
            .collection('series')
            .doc('To Remove')
            .set({
              'id': 111,
              'totalHours': 0.0,
              'isFavorite': true,
              'imageUrl': '',
              'episode': '',
              'lastEpisodeTitle': '',
            });

        await AppData.initializeData();
        await AppData.setSeriesFavorite('To Remove', 111, false);

        final seriesDoc = await fakeDb
            .collection('users')
            .doc('test_uid')
            .collection('series')
            .doc('To Remove')
            .get();
        expect(seriesDoc.exists, isFalse);
      },
    );
    test('userStream e seriesStream devono restituire stream validi', () async {
      await AppData.initializeData();

      final uStream = AppData.userStream();
      expect(uStream, isNotNull);

      final sStream = AppData.seriesStream();
      expect(sStream, isNotNull);
    });

    test(
      'claimBadge deve aggiungere un badge all\'array su Firestore',
      () async {
        await AppData.initializeData();

        await AppData.claimBadge('badge_test_123');

        final userDoc = await fakeDb.collection('users').doc('test_uid').get();
        final claimed = List<String>.from(
          userDoc.data()!['claimedBadgeIds'] ?? [],
        );

        expect(claimed, contains('badge_test_123'));
      },
    );

    test('setSeriesFavorite deve aggiornare una serie ESISTENTE', () async {
      await fakeDb
          .collection('users')
          .doc('test_uid')
          .collection('series')
          .doc('Existing')
          .set({
            'id': 555,
            'totalHours': 10.0,
            'isFavorite': false,
            'imageUrl': '',
            'episode': '',
            'lastEpisodeTitle': '',
          });

      await AppData.initializeData();

      await AppData.setSeriesFavorite('Existing', 555, true);

      final seriesDoc = await fakeDb
          .collection('users')
          .doc('test_uid')
          .collection('series')
          .doc('Existing')
          .get();
      expect(seriesDoc.data()!['isFavorite'], isTrue);

      final localIndex = AppData.userSeries.indexWhere(
        (s) => s.name == 'Existing',
      );
      expect(AppData.userSeries[localIndex].isFavorite, isTrue);
    });
  });
}
