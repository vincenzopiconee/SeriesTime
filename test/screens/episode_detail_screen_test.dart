import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:seriestime/models/actor.dart';
import 'package:seriestime/models/episode.dart';
import 'package:seriestime/screens/episode_detail_screen.dart';

void main() {
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
    AppData.currentUser = null;
  });

  tearDown(() {
    AppData.currentUser = null;
  });

  Episode createTestEpisode({
    bool withGuestStars = false,
    String? airDate,
    double voteAverage = 8.5,
    int runtime = 45,
  }) {
    return Episode(
      id: 1,
      name: 'Test Episode',
      episodeNumber: 1,
      overview: 'Test overview',
      airDate: airDate ?? '2024-01-01',
      runtime: runtime,
      voteAverage: voteAverage,
      stillUrl: null,
      guestStars: withGuestStars
          ? [
              Actor(
                name: 'Guest Actor',
                characterName: 'Guest Character',
                profileUrl: null,
              ),
            ]
          : [],
    );
  }

  group('EpisodeDetailScreen - UI Components', () {
    testWidgets('shows AppBar with correct title', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = createTestEpisode();

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Series - S1 E1'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays episode information', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = createTestEpisode();

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Episode'), findsOneWidget);
      expect(find.text('S1 E1'), findsAtLeastNWidgets(1));
      expect(find.text('8.5'), findsOneWidget);
    });

    testWidgets('displays overview section', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = createTestEpisode();

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Test overview'), findsOneWidget);
    });

    testWidgets('shows air date and runtime badges', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = createTestEpisode();

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2024-01-01'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });
  });

  group('EpisodeDetailScreen - Guest Stars', () {
    testWidgets('shows guest stars section when present', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = createTestEpisode(withGuestStars: true);

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Guest Stars'), findsOneWidget);
      expect(find.text('Guest Actor'), findsOneWidget);
      expect(find.text('Guest Character'), findsOneWidget);
    });

    testWidgets('hides guest stars section when empty', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = createTestEpisode(withGuestStars: false);

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Guest Stars'), findsNothing);
    });
  });

  group('EpisodeDetailScreen - Watched Toggle', () {
    testWidgets('shows Not Watched for unwatched episode', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = createTestEpisode();

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not Watched'), findsOneWidget);
    });

    testWidgets('shows Watched for watched episode', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Test Series')
          .collection('seasons')
          .doc('Season 1')
          .collection('episodes')
          .doc('Episode 1')
          .set({'watched': true});

      final episode = createTestEpisode();

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Watched'), findsOneWidget);
    });

    testWidgets('shows Not Released for future episodes', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final futureDate = DateTime.now().add(const Duration(days: 30));
      final episode = createTestEpisode(
        airDate: futureDate.toIso8601String().split('T')[0],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not Released'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });
  });

  group('EpisodeDetailScreen - Edge Cases', () {
    testWidgets('shows placeholder when no still image', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = createTestEpisode();

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });

    testWidgets('shows default message for empty overview', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = Episode(
        id: 1,
        name: 'Test Episode',
        episodeNumber: 1,
        overview: '',
        airDate: '2024-01-01',
        runtime: 45,
        voteAverage: 8.5,
        stillUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No description available.'), findsOneWidget);
    });

    testWidgets('hides rating when vote average is 0', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = createTestEpisode(voteAverage: 0.0);

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('hides runtime badge when runtime is 0', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      final episode = createTestEpisode(runtime: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 min'), findsNothing);
    });

    testWidgets('handles null user data', (tester) async {
      final episode = createTestEpisode();

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeDetailScreen(
            seriesName: 'Test Series',
            seriesId: 123,
            seasonNumber: 1,
            episode: episode,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(EpisodeDetailScreen), findsOneWidget);
    });
  });
}
