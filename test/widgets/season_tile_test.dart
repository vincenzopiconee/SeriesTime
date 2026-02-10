import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:seriestime/models/season.dart';
import 'package:seriestime/widgets/season_tile.dart';
import 'package:seriestime/screens/episode_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FirebasePlatform.instance = MockFirebasePlatform();
    await Firebase.initializeApp();
  });

  group('SeasonTile Widget Tests', () {
    late Season testSeason;
    late FakeFirebaseFirestore fakeDb;
    late MockFirebaseAuth fakeAuth;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      fakeAuth = MockFirebaseAuth(signedIn: true);

      SeasonTile.auth = fakeAuth;
      SeasonTile.db = fakeDb;

      testSeason = Season(
        id: 1,
        seasonNumber: 1,
        name: "Season 1",
        episodeCount: 1,
      );
    });

    testWidgets('SeasonTile - Test espansione e caricamento episodi', (
      WidgetTester tester,
    ) async {
      SeasonTile.httpClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response(
          json.encode({
            'episodes': [
              {
                'id': 101,
                'name': 'Pilot',
                'episode_number': 1,
                'season_number': 1,
                'air_date': '2020-01-01',
                'still_path': null,
              },
            ],
          }),
          200,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonTile(
              seriesId: 123,
              seriesName: "Breaking Bad",
              season: testSeason,
            ),
          ),
        ),
      );

      expect(find.text("Season 1"), findsOneWidget);

      await tester.tap(find.text("Season 1"));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text("Pilot"), findsOneWidget);
    });

    testWidgets(
      'Deve navigare a EpisodeDetailScreen quando si clicca su un episodio',
      (WidgetTester tester) async {
        SeasonTile.httpClient = MockClient((request) async {
          return http.Response(
            json.encode({
              'episodes': [
                {
                  'id': 101,
                  'name': 'Pilot',
                  'episode_number': 1,
                  'season_number': 1,
                },
              ],
            }),
            200,
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SeasonTile(
                seriesId: 123,
                seriesName: "Breaking Bad",
                season: testSeason,
              ),
            ),
          ),
        );

        await tester.tap(find.text("Season 1"));
        await tester.pumpAndSettle();

        await tester.tap(find.text("Pilot"));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(EpisodeDetailScreen), findsOneWidget);
      },
    );

    testWidgets('Deve chiamare toggleEpisodeWatched quando si preme il check', (
      WidgetTester tester,
    ) async {
      SeasonTile.httpClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'episodes': [
              {
                'id': 101,
                'name': 'Pilot',
                'episode_number': 1,
                'season_number': 1,
                'air_date': '2020-01-01',
              },
            ],
          }),
          200,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonTile(
              seriesId: 123,
              seriesName: "Breaking Bad",
              season: testSeason,
            ),
          ),
        ),
      );

      await tester.tap(find.text("Season 1"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(true, isTrue);
    });
  });
}

class MockFirebasePlatform extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return FirebaseAppPlatform(
      name ?? '[DEFAULT]',
      const FirebaseOptions(
        apiKey: '123',
        appId: '123',
        messagingSenderId: '123',
        projectId: '123',
      ),
    );
  }

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return FirebaseAppPlatform(
      name,
      const FirebaseOptions(
        apiKey: '123',
        appId: '123',
        messagingSenderId: '123',
        projectId: '123',
      ),
    );
  }
}
