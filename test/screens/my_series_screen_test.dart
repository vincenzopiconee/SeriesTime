import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/screens/my_series_screen.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('MySeriesScreen - Complete Coverage', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockClient mockHttpClient;

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

      mockHttpClient = MockClient((request) async {
        return http.Response(
          '{"id": 1, "name": "Test Episode", "episode_number": 1, "overview": "Test", "air_date": "2024-01-01", "runtime": 45, "vote_average": 8.0, "still_path": "/test.jpg"}',
          200,
        );
      });
    });

    testWidgets('shows loading indicator', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows tabs', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      expect(find.text("Favorites"), findsOneWidget);
      expect(find.text("Watching"), findsOneWidget);
      expect(find.text("Upcoming"), findsOneWidget);
    });

    testWidgets('shows empty favorites', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      expect(
        find.text("No favorites yet.\nAdd series from Explore!"),
        findsOneWidget,
      );
    });

    testWidgets('displays favorites', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Breaking Bad')
          .set({
            'id': 1,
            'imageUrl': 'https://test.com/image.jpg',
            'percentage': 0.5,
            'episode': 'S1 E1',
            'isFavorite': true,
          });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays watching series with episode', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Game of Thrones')
          .set({
            'id': 2,
            'imageUrl': 'https://test.com/image2.jpg',
            'percentage': 0.3,
            'episode': 'S2 E5',
            'lastEpisodeTitle': 'The Ghost of Harrenhal',
            'isFavorite': false,
          });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      final tabs = find.byType(Tab);
      await tester.tap(tabs.at(1));
      await tester.pumpAndSettle();

      expect(find.byType(WatchingEpisodeCard), findsOneWidget);
    });

    testWidgets('handles future episode date', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final futureDate = DateTime.now().add(const Duration(days: 5));
      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Future Show')
          .set({
            'id': 3,
            'imageUrl': 'https://test.com/image3.jpg',
            'percentage': 0.2,
            'episode': 'S1 E1',
            'lastEpisodeTitle': 'Pilot',
            'nextEpisodeAirDate': futureDate.toIso8601String(),
            'isFavorite': false,
          });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      final tabs = find.byType(Tab);
      await tester.tap(tabs.at(1));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('sorts by lastWatched null cases', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Series1')
          .set({
            'id': 1,
            'imageUrl': 'https://test.com/1.jpg',
            'percentage': 0.5,
            'isFavorite': true,
          });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Series2')
          .set({
            'id': 2,
            'imageUrl': 'https://test.com/2.jpg',
            'percentage': 0.5,
            'lastWatched': Timestamp.now(),
            'isFavorite': true,
          });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('handles invalid episode format', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Bad Format')
          .set({
            'id': 4,
            'imageUrl': 'https://test.com/4.jpg',
            'percentage': 0.4,
            'episode': 'Invalid',
            'lastEpisodeTitle': 'Title',
            'isFavorite': false,
          });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      final tabs = find.byType(Tab);
      await tester.tap(tabs.at(1));
      await tester.pumpAndSettle();

      expect(find.byType(WatchingEpisodeCard), findsOneWidget);
    });

    testWidgets('shows watching card with check button', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Checkable')
          .set({
            'id': 5,
            'imageUrl': 'https://test.com/5.jpg',
            'percentage': 0.5,
            'episode': 'S1 E1',
            'lastEpisodeTitle': 'Pilot',
            'isFavorite': false,
          });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      final tabs = find.byType(Tab);
      await tester.tap(tabs.at(1));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('SeriesListCard exists', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Tappable')
          .set({
            'id': 6,
            'imageUrl': 'https://test.com/6.jpg',
            'percentage': 0.5,
            'episode': 'S1 E1',
            'isFavorite': true,
          });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      expect(find.byType(SeriesListCard), findsOneWidget);
    });

    testWidgets('WatchingEpisodeCard shows days left', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchingEpisodeCard(
              imageUrl: 'https://test.com/test.jpg',
              mainText: 'Episode',
              subText: 'Series',
              episodeLabel: 'S1 E1',
              isUpcoming: true,
              daysLeft: 5,
            ),
          ),
        ),
      );

      expect(find.text("5"), findsOneWidget);
      expect(find.text("days"), findsOneWidget);
    });

    testWidgets('WatchingEpisodeCard shows extraInfo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchingEpisodeCard(
              imageUrl: 'https://test.com/test.jpg',
              mainText: 'Episode',
              subText: 'Series',
              episodeLabel: 'S1 E1',
              extraInfo: '2024-01-01',
            ),
          ),
        ),
      );

      expect(find.text("2024-01-01"), findsOneWidget);
    });

    testWidgets('WatchingEpisodeCard handles check tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchingEpisodeCard(
              imageUrl: 'https://test.com/test.jpg',
              mainText: 'Episode',
              subText: 'Series',
              episodeLabel: 'S1 E1',
              onCheckTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('shows MySeriesScreen', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MySeriesScreen(httpClient: mockHttpClient)),
      );
      await tester.pump();

      expect(find.byType(MySeriesScreen), findsOneWidget);
    });
  });
}
