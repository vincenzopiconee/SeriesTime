import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/screens/series_detail_screen.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SeriesDetailScreen Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockUser = MockUser(
        uid: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      AppData.db = fakeFirestore;
      AppData.firebaseAuth = mockAuth;
      AppData.resetData();
    });

    Future<void> setupUserData() async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 100.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 20.0,
        'nightOwlHours': 15.0,
        'uniqueGenresCount': 3,
        'seriesStreak': 2,
        'claimedBadgeIds': [],
        'photoUrl': null,
      });
    }

    http.Client createMockClient({
      int statusCode = 200,
      Map<String, dynamic>? responseData,
    }) {
      final defaultResponse = {
        "id": 1396,
        "name": "Breaking Bad",
        "tagline": "All Hail the King",
        "overview": "A high school chemistry teacher diagnosed with cancer...",
        "poster_path": "/ggFHVNu6YYI5L9pCfOacjizRGt.jpg",
        "backdrop_path": "/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg",
        "first_air_date": "2008-01-20",
        "status": "Ended",
        "number_of_seasons": 5,
        "number_of_episodes": 62,
        "vote_average": 8.9,
        "vote_count": 12500,
        "genres": [
          {"id": 18, "name": "Drama"},
          {"id": 80, "name": "Crime"},
        ],
        "networks": [
          {"id": 174, "name": "AMC"},
        ],
        "created_by": [
          {"id": 66633, "name": "Vince Gilligan"},
        ],
        "seasons": [
          {
            "id": 3572,
            "season_number": 1,
            "name": "Season 1",
            "episode_count": 7,
            "air_date": "2008-01-20",
            "poster_path": "/1BP4xYv9ZG4ZVHkL7ocOziBbSYH.jpg",
            "overview": "The first season overview",
          },
          {
            "id": 3573,
            "season_number": 2,
            "name": "Season 2",
            "episode_count": 13,
            "air_date": "2009-03-08",
            "poster_path": "/e3oGYpoTUhOFK0BJfloru5ZmfHD.jpg",
            "overview": "The second season overview",
          },
        ],
        "aggregate_credits": {
          "cast": [
            {
              "id": 17419,
              "name": "Bryan Cranston",
              "roles": [
                {"character": "Walter White"},
              ],
              "profile_path": "/7Jahy5LZX2Fo8fGJltMjeme6LO.jpg",
            },
            {
              "id": 134531,
              "name": "Aaron Paul",
              "roles": [
                {"character": "Jesse Pinkman"},
              ],
              "profile_path": "/oTceEUb6A9Bg6DeUTJBTETUOEFu.jpg",
            },
          ],
        },
        "watch/providers": {
          "results": {
            "US": {
              "flatrate": [
                {
                  "provider_id": 8,
                  "provider_name": "Netflix",
                  "logo_path": "/t2yyOv40HZeVlLjYsCsPHnWLk4W.jpg",
                },
              ],
            },
          },
        },
        "last_episode_to_air": {
          "id": 62161,
          "name": "Felina",
          "overview": "The series finale",
          "season_number": 5,
          "episode_number": 16,
          "air_date": "2013-09-29",
        },
      };

      final response = responseData ?? defaultResponse;

      return MockClient((request) async {
        return http.Response(
          json.encode(response),
          statusCode,
          headers: {'content-type': 'application/json'},
        );
      });
    }

    testWidgets('shows loading indicator initially', (tester) async {
      await setupUserData();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SeriesDetailScreen(
              seriesId: 1396,
              seriesName: 'Breaking Bad',
              httpClient: createMockClient(),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    testWidgets('displays series details after loading', (tester) async {
      await setupUserData();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SeriesDetailScreen(
              seriesId: 1396,
              seriesName: 'Breaking Bad',
              httpClient: createMockClient(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Breaking Bad'), findsWidgets);
        expect(find.byType(TabBar), findsOneWidget);
      });
    });

    testWidgets('displays series header with poster and backdrop', (
      tester,
    ) async {
      await setupUserData();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SeriesDetailScreen(
              seriesId: 1396,
              seriesName: 'Breaking Bad',
              httpClient: createMockClient(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Image), findsWidgets);
      });
    });

    testWidgets('shows tagline when available', (tester) async {
      await setupUserData();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SeriesDetailScreen(
              seriesId: 1396,
              seriesName: 'Breaking Bad',
              httpClient: createMockClient(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('All Hail the King'), findsOneWidget);
      });
    });

    testWidgets('displays favorite button', (tester) async {
      await setupUserData();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SeriesDetailScreen(
              seriesId: 1396,
              seriesName: 'Breaking Bad',
              httpClient: createMockClient(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star_border), findsOneWidget);
        expect(find.text('Add to Favorites'), findsOneWidget);
      });
    });

    testWidgets('toggles favorite status when button tapped', (tester) async {
      await setupUserData();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SeriesDetailScreen(
              seriesId: 1396,
              seriesName: 'Breaking Bad',
              httpClient: createMockClient(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final favoriteButton = find.byIcon(Icons.star_border);
        await tester.tap(favoriteButton);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.text('Favorited'), findsOneWidget);
      });
    });

    testWidgets('displays Info and Episodes tabs', (tester) async {
      await setupUserData();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SeriesDetailScreen(
              seriesId: 1396,
              seriesName: 'Breaking Bad',
              httpClient: createMockClient(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Info'), findsOneWidget);
        expect(find.text('Episodes'), findsOneWidget);
      });
    });

    testWidgets('shows app bar title when scrolled down', (tester) async {
      await setupUserData();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SeriesDetailScreen(
              seriesId: 1396,
              seriesName: 'Breaking Bad',
              httpClient: createMockClient(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.drag(find.byType(NestedScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Breaking Bad'), findsWidgets);
      });
    });

    testWidgets('handles missing poster gracefully', (tester) async {
      await setupUserData();

      final responseNoPoster = {
        "id": 1396,
        "name": "Breaking Bad",
        "tagline": "",
        "overview": "Overview",
        "poster_path": null,
        "backdrop_path": null,
        "first_air_date": "2008-01-20",
        "status": "Ended",
        "number_of_seasons": 5,
        "number_of_episodes": 62,
        "vote_average": 8.9,
        "vote_count": 12500,
        "genres": [],
        "networks": [],
        "created_by": [],
        "seasons": [],
        "aggregate_credits": {"cast": []},
        "watch/providers": {"results": {}},
      };

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SeriesDetailScreen(
              seriesId: 1396,
              seriesName: 'Breaking Bad',
              httpClient: createMockClient(responseData: responseNoPoster),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    testWidgets('disposes resources properly', (tester) async {
      await setupUserData();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SeriesDetailScreen(
              seriesId: 1396,
              seriesName: 'Breaking Bad',
              httpClient: createMockClient(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));

        expect(tester.takeException(), isNull);
      });
    });
  });
}
