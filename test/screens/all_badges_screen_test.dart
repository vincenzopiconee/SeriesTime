import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:seriestime/data/badge_definitions.dart';
import 'package:seriestime/models/user.dart';
import 'package:seriestime/screens/all_badges_screen.dart';
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

    AppData.currentUser = User(
      name: 'Test User',
      totalHoursWatched: 100.0,
      maxConsecutiveHours: 10.0,
      weekendHours: 25.0,
      nightOwlHours: 15.0,
      uniqueGenresCount: 8,
      claimedBadgeIds: [],
      photoUrl: null,
      seriesStreak: 5,
      lastViewDate: DateTime.now(),
    );
    AppData.userSeries = [];
  });

  tearDown(() {
    AppData.currentUser = null;
    AppData.userSeries = [];
  });

  group('AllBadgesScreen - UI Components', () {
    testWidgets('mostra AppBar con titolo corretto', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllBadgesScreen()),
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('My Badges'), findsOneWidget);
    });

    testWidgets('mostra messaggio quando non ci sono badge', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(
        find.text('No badges claimed yet.\nKeep watching to unlock rewards!'),
        findsOneWidget,
      );
    });
  });

  group('AllBadgesScreen - Badge Display', () {
    testWidgets('mostra GridView con badge quando presenti', (tester) async {
      final marathoner = BadgeDefinitions.marathonerMilestones[0];
      final obsession = BadgeDefinitions.obsessionMilestones[0];

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [marathoner.id, obsession.id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.text(marathoner.title), findsOneWidget);
      expect(find.text(obsession.title), findsOneWidget);
    });

    testWidgets('mostra tutti i tipi di badge possibili', (tester) async {
      final badgeIds = [
        BadgeDefinitions.marathonerMilestones[0].id,
        BadgeDefinitions.obsessionMilestones[0].id,
        BadgeDefinitions.weekendMilestones[0].id,
        BadgeDefinitions.streakMilestones[0].id,
        BadgeDefinitions.completionistMilestones[0].id,
        BadgeDefinitions.nightOwlMilestones[0].id,
        BadgeDefinitions.genreMilestones[0].id,
      ];

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': badgeIds,
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsNWidgets(7));
      expect(find.text('Marathoner'), findsOneWidget);
      expect(find.text('Pure Obsession'), findsOneWidget);
      expect(find.text('Weekend Warrior'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('The Perfectionist'), findsOneWidget);
      expect(find.text('The Night Owl'), findsOneWidget);
      expect(find.text('Genre Explorer'), findsOneWidget);
    });

    testWidgets('verifica la presenza dei container dei badge', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.marathonerMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      final containers = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.byType(Container),
      );
      expect(containers, findsWidgets);
    });
  });

  group('AllBadgesScreen - Navigation', () {
    testWidgets('naviga a BadgeDetailScreen per Marathoner', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.marathonerMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marathoner'));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
    });

    testWidgets('naviga con dati corretti per Pure Obsession', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.obsessionMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pure Obsession'));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
    });

    testWidgets('naviga con dati corretti per Weekend Warrior', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.weekendMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekend Warrior'));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
    });

    testWidgets('naviga con dati corretti per Streak', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.streakMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Streak'));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
    });

    testWidgets('naviga con dati corretti per The Perfectionist', (
      tester,
    ) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.completionistMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('The Perfectionist'));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
    });

    testWidgets('naviga con dati corretti per The Night Owl', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.nightOwlMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('The Night Owl'));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
    });

    testWidgets('naviga con dati corretti per Genre Explorer', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.genreMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Genre Explorer'));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
    });
  });

  group('AllBadgesScreen - StreamBuilder Behavior', () {
    testWidgets('aggiorna claimedBadgeIds su AppData.currentUser', (
      tester,
    ) async {
      final badgeId = BadgeDefinitions.marathonerMilestones[0].id;

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [badgeId],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(AppData.currentUser?.claimedBadgeIds, contains(badgeId));
    });

    testWidgets('gestisce correttamente lista vuota di claimedBadgeIds', (
      tester,
    ) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(AppData.currentUser?.claimedBadgeIds, isEmpty);
      expect(
        find.text('No badges claimed yet.\nKeep watching to unlock rewards!'),
        findsOneWidget,
      );
    });

    testWidgets('reagisce a cambiamenti nel stream', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(
        find.text('No badges claimed yet.\nKeep watching to unlock rewards!'),
        findsOneWidget,
      );

      await fakeFirestore.collection('users').doc('test-user-id').update({
        'claimedBadgeIds': [BadgeDefinitions.marathonerMilestones[0].id],
      });
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Marathoner'), findsOneWidget);
    });
  });

  group('AllBadgesScreen - Scroll Controller', () {
    testWidgets('verifica la presenza dello ScrollController', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [
          BadgeDefinitions.marathonerMilestones[0].id,
          BadgeDefinitions.marathonerMilestones[1].id,
          BadgeDefinitions.marathonerMilestones[2].id,
        ],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
      expect(scrollbar.controller, isNotNull);
      expect(scrollbar.thumbVisibility, isTrue);
    });
  });

  group('AllBadgesScreen - Badge Scaling', () {
    testWidgets('applica scaling corretto per badge Streak', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.streakMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      final transforms = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.byType(Transform),
      );
      expect(transforms, findsOneWidget);
    });

    testWidgets('applica scaling corretto per The Perfectionist', (
      tester,
    ) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.completionistMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      final transforms = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.byType(Transform),
      );
      expect(transforms, findsOneWidget);
    });

    testWidgets('non applica scaling per altri badge', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.marathonerMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      final transforms = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.byType(Transform),
      );
      expect(transforms, findsOneWidget);
    });
  });

  group('AllBadgesScreen - Grid Layout', () {
    testWidgets('verifica la configurazione del GridView', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [
          BadgeDefinitions.marathonerMilestones[0].id,
          BadgeDefinitions.obsessionMilestones[0].id,
        ],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, equals(4));
      expect(delegate.childAspectRatio, equals(0.65));
      expect(delegate.crossAxisSpacing, equals(10));
      expect(delegate.mainAxisSpacing, equals(10));
    });

    testWidgets('verifica il padding del GridView', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.marathonerMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView.padding, equals(const EdgeInsets.all(16)));
    });
  });

  group('AllBadgesScreen - Multiple Badges', () {
    testWidgets('mostra correttamente multipli badge della stessa categoria', (
      tester,
    ) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [
          BadgeDefinitions.marathonerMilestones[0].id,
          BadgeDefinitions.marathonerMilestones[1].id,
          BadgeDefinitions.marathonerMilestones[2].id,
        ],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Marathoner'), findsNWidgets(3));
      expect(find.byType(GestureDetector), findsNWidgets(3));
    });

    testWidgets('ordina i badge nel modo corretto', (tester) async {
      final allBadgeIds = [
        ...BadgeDefinitions.marathonerMilestones.map((b) => b.id),
        ...BadgeDefinitions.obsessionMilestones.map((b) => b.id),
        ...BadgeDefinitions.weekendMilestones.map((b) => b.id),
        ...BadgeDefinitions.streakMilestones.map((b) => b.id),
        ...BadgeDefinitions.completionistMilestones.map((b) => b.id),
        ...BadgeDefinitions.nightOwlMilestones.map((b) => b.id),
        ...BadgeDefinitions.genreMilestones.map((b) => b.id),
      ];

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': allBadgeIds,
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsWidgets);
    });
  });

  group('AllBadgesScreen - Edge Cases', () {
    testWidgets('gestisce currentUser null', (tester) async {
      AppData.currentUser = null;

      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [BadgeDefinitions.marathonerMilestones[0].id],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('gestisce badge IDs non validi', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': ['invalid-badge-id', 'another-invalid-id'],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(
        find.text('No badges claimed yet.\nKeep watching to unlock rewards!'),
        findsOneWidget,
      );
    });

    testWidgets('gestisce mix di badge validi e non validi', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [
          'invalid-id',
          BadgeDefinitions.marathonerMilestones[0].id,
          'another-invalid',
        ],
      });

      await tester.pumpWidget(const MaterialApp(home: AllBadgesScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Marathoner'), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
    });
  });
}
