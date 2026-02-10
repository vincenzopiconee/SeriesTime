import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:seriestime/data/badge_definitions.dart';

import 'package:seriestime/screens/binge_mode_screen.dart';
import 'package:seriestime/screens/badge_detail_screen.dart';

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
    AppData.userSeries = [];
  });

  tearDown(() {
    AppData.currentUser = null;
    AppData.userSeries = [];
  });

  group('BingeModeScreen - UI Components', () {
    testWidgets('shows AppBar with title and tabs', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 50.0,
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Binge Mode'), findsOneWidget);
      expect(find.text('Quests'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('displays DefaultTabController with 2 tabs', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 50.0,
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(DefaultTabController), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });
  });

  group('BingeModeScreen - Quests Tab', () {
    testWidgets('shows quest items in Quests tab', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 50.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 10.0,
        'nightOwlHours': 3.0,
        'seriesStreak': 2,
        'uniqueGenresCount': 4,
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Marathoner'), findsOneWidget);
      expect(find.text('Pure Obsession'), findsOneWidget);
      expect(find.text('Weekend Warrior'), findsOneWidget);
    });

    testWidgets('shows READY TO CLAIM for completed quest', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 100.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 10.0,
        'nightOwlHours': 3.0,
        'seriesStreak': 2,
        'uniqueGenresCount': 4,
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('READY TO CLAIM'), findsWidgets);
    });

    testWidgets('shows CLAIM REWARD button for completed quest', (
      tester,
    ) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 100.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 10.0,
        'nightOwlHours': 3.0,
        'seriesStreak': 2,
        'uniqueGenresCount': 4,
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('CLAIM REWARD'), findsWidgets);
    });

    testWidgets('hides claimed quests from Quests tab', (tester) async {
      final firstBadgeId = BadgeDefinitions.marathonerMilestones[0].id;

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 100.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 10.0,
        'nightOwlHours': 3.0,
        'seriesStreak': 2,
        'uniqueGenresCount': 4,
        'claimedBadgeIds': [firstBadgeId],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('BingeModeScreen - Completed Tab', () {
    testWidgets('shows empty message when no badges claimed', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 50.0,
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(
        find.text('No badges claimed yet.\nComplete a quest and click CLAIM!'),
        findsOneWidget,
      );
    });

    testWidgets('shows claimed badges in Completed tab', (tester) async {
      final badgeId = BadgeDefinitions.marathonerMilestones[0].id;

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 100.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 10.0,
        'nightOwlHours': 3.0,
        'seriesStreak': 2,
        'uniqueGenresCount': 4,
        'claimedBadgeIds': [badgeId],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Marathoner'), findsOneWidget);
      expect(find.text('CLAIMED'), findsOneWidget);
    });

    testWidgets('shows multiple claimed badges', (tester) async {
      final badgeIds = [
        BadgeDefinitions.marathonerMilestones[0].id,
        BadgeDefinitions.obsessionMilestones[0].id,
      ];

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 100.0,
        'maxConsecutiveHours': 10.0,
        'weekendHours': 10.0,
        'nightOwlHours': 3.0,
        'seriesStreak': 2,
        'uniqueGenresCount': 4,
        'claimedBadgeIds': badgeIds,
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Marathoner'), findsOneWidget);
      expect(find.text('Pure Obsession'), findsOneWidget);
    });
  });

  group('BingeModeScreen - Navigation', () {
    testWidgets('navigates to BadgeDetailScreen on quest tap', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 50.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 10.0,
        'nightOwlHours': 3.0,
        'seriesStreak': 2,
        'uniqueGenresCount': 4,
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marathoner').first);
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
    });

    testWidgets('navigates from Completed tab to BadgeDetailScreen', (
      tester,
    ) async {
      final badgeId = BadgeDefinitions.marathonerMilestones[0].id;

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 100.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 10.0,
        'nightOwlHours': 3.0,
        'seriesStreak': 2,
        'uniqueGenresCount': 4,
        'claimedBadgeIds': [badgeId],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marathoner'));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
    });
  });

  group('BingeModeScreen - Special Scaling', () {
    testWidgets('applies special scaling for Streak badge', (tester) async {
      final badgeId = BadgeDefinitions.streakMilestones[0].id;

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 50.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 10.0,
        'nightOwlHours': 3.0,
        'seriesStreak': 10,
        'uniqueGenresCount': 4,
        'claimedBadgeIds': [badgeId],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Streak'), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('applies special scaling for Perfectionist badge', (
      tester,
    ) async {
      final badgeId = BadgeDefinitions.completionistMilestones[0].id;

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 50.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 10.0,
        'nightOwlHours': 3.0,
        'seriesStreak': 2,
        'uniqueGenresCount': 4,
        'claimedBadgeIds': [badgeId],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('The Perfectionist'), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('BingeModeScreen - Edge Cases', () {
    testWidgets('handles missing user data fields', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(BingeModeScreen), findsOneWidget);
    });

    testWidgets('handles empty series list', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'totalHoursWatched': 0.0,
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(const MaterialApp(home: BingeModeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Marathoner'), findsOneWidget);
    });
  });
}
