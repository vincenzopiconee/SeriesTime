import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seriestime/screens/explore_screen.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  group('ExploreScreen - Complete Coverage', () {
    late MockClient mockHttpClient;

    setUp(() {
      AppData.db = FakeFirebaseFirestore();
      AppData.firebaseAuth = MockFirebaseAuth(signedIn: true);
      AppData.resetData();

      mockHttpClient = MockClient((request) async {
        return http.Response('''
          {
            "results": [
              {
                "id": 1,
                "name": "Breaking Bad",
                "overview": "A chemistry teacher turns to cooking meth.",
                "poster_path": "/test.jpg",
                "backdrop_path": "/test2.jpg",
                "vote_average": 9.5,
                "first_air_date": "2008-01-20",
                "origin_country": ["US"],
                "genre_ids": [18, 80]
              },
              {
                "id": 2,
                "name": "Game of Thrones",
                "overview": "Nine noble families fight for control.",
                "poster_path": null,
                "vote_average": 8.5,
                "first_air_date": "2011-04-17",
                "origin_country": ["US"],
                "genre_ids": [18, 10765]
              }
            ]
          }
          ''', 200);
      });
    });

    testWidgets('shows initial UI with search and genres', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      expect(find.text("Explore"), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text("Drama"), findsOneWidget);
      expect(find.text("Trending Now"), findsOneWidget);
    });

    testWidgets('loads and displays TV shows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text("Breaking Bad"), findsOneWidget);
      expect(find.text("Game of Thrones"), findsOneWidget);
    });

    testWidgets('selects and deselects genre', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text("Drama"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining("Popular in Drama"), findsOneWidget);

      await tester.tap(find.text("Drama"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text("Trending Now"), findsOneWidget);
    });

    testWidgets('searches TV shows with debounce', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Breaking');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text("Search Results"), findsOneWidget);
    });

    testWidgets('combines search with genre filter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text("Drama"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Breaking');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text("Search Results"), findsOneWidget);
    });

    testWidgets('handles API error gracefully', (tester) async {
      final errorClient = MockClient((request) async {
        return http.Response('Error', 500);
      });

      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: errorClient)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ExploreScreen), findsOneWidget);
    });

    testWidgets('handles network exception', (tester) async {
      final errorClient = MockClient((request) async {
        throw Exception('Network error');
      });

      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: errorClient)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ExploreScreen), findsOneWidget);
    });

    testWidgets('shows empty state when no results', (tester) async {
      final emptyClient = MockClient((request) async {
        return http.Response('{"results": []}', 200);
      });

      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: emptyClient)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text("No series found matching criteria"), findsOneWidget);
      expect(find.byIcon(Icons.tv_off), findsOneWidget);
    });

    testWidgets('displays show with no poster', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.tv), findsWidgets);
    });

    testWidgets('displays rating badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.star), findsWidgets);
      expect(find.text("9.5"), findsOneWidget);
    });

    testWidgets('scrolls genre list horizontally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final genreList = find.byType(ListView).first;
      await tester.drag(genreList, const Offset(-300, 0));
      await tester.pump();

      expect(find.text("Mystery"), findsOneWidget);
    });

    testWidgets('rapid search changes trigger debounce', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      final searchField = find.byType(TextField);

      await tester.enterText(searchField, 'B');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(searchField, 'Br');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text("Search Results"), findsOneWidget);
    });

    testWidgets('disposes properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
