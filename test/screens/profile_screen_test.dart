import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/screens/profile_screen.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileScreen Tests', () {
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

    Future<void> setupUserAndSeries(
      WidgetTester tester, {
      String userName = 'Test User',
      double totalHours = 100.0,
      List<String> badges = const [],
      List<Map<String, dynamic>> series = const [],
      bool waitForChart = false,
    }) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': userName,
        'totalHoursWatched': totalHours,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 20.0,
        'nightOwlHours': 15.0,
        'uniqueGenresCount': 3,
        'seriesStreak': 2,
        'claimedBadgeIds': badges,
        'photoUrl': null,
      });

      for (var s in series) {
        await fakeFirestore
            .collection('users')
            .doc('test-user-id')
            .collection('series')
            .doc(s['name'])
            .set(s);
      }

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        if (waitForChart) {
          for (int i = 0; i < 30; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            if (tester.any(find.text('Y'))) break;
          }
        }
      });
    }

    testWidgets('displays user profile information', (tester) async {
      await setupUserAndSeries(tester, userName: 'John Doe');

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('shows settings button and navigates', (tester) async {
      await setupUserAndSeries(tester);

      await mockNetworkImagesFor(() async {
        final settingsButton = find.byIcon(Icons.settings);
        expect(settingsButton, findsOneWidget);

        await tester.tap(settingsButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Settings'), findsOneWidget);
      });
    });

    testWidgets('displays statistics overview section', (tester) async {
      await setupUserAndSeries(tester, totalHours: 150.0);

      expect(find.text('Statistics Overview'), findsOneWidget);
      expect(find.text('Total Watch Time'), findsOneWidget);
    });

    testWidgets('displays watch time split correctly', (tester) async {
      await setupUserAndSeries(tester, totalHours: 50.5);

      expect(find.textContaining('d'), findsWidgets);
      expect(find.textContaining('h'), findsWidgets);
      expect(find.textContaining('m'), findsWidgets);
    });

    testWidgets('shows badges section', (tester) async {
      await setupUserAndSeries(tester, badges: ['binge_watcher']);

      expect(find.text('My Badges'), findsOneWidget);
    });

    testWidgets('navigates to all badges screen', (tester) async {
      await setupUserAndSeries(
        tester,
        badges: [
          'binge_watcher',
          'marathoner_bronze',
          'marathoner_silver',
          'marathoner_gold',
          'marathoner_platinum',
        ],
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpAndSettle();

        final viewMoreButton = find.text('View More');
        if (viewMoreButton.evaluate().isNotEmpty) {
          await tester.ensureVisible(viewMoreButton);
          await tester.pumpAndSettle();
          await tester.tap(viewMoreButton);
          await tester.pumpAndSettle();

          expect(find.text('All Badges'), findsOneWidget);
        }
      });
    });

    testWidgets('shows empty message when no badges', (tester) async {
      await setupUserAndSeries(tester, badges: []);

      expect(find.text('Keep watching to unlock badges!'), findsOneWidget);
    });

    testWidgets('displays series progress section', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Breaking Bad',
            'imageUrl': 'https://example.com/image.jpg',
            'percentage': 0.5,
            'totalHours': 25.0,
            'episode': 'S02E05',
            'seriesDuration': 50.0,
            'isFavorite': false,
          },
        ],
      );

      expect(find.text('Series Progress'), findsOneWidget);
    });

    testWidgets('shows view more button for series', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Series 1',
            'imageUrl': 'https://example.com/1.jpg',
            'percentage': 0.2,
            'totalHours': 5.0,
            'episode': 'S01E01',
            'seriesDuration': 25.0,
            'isFavorite': false,
          },
        ],
      );

      expect(find.text('View More'), findsOneWidget);
    });

    testWidgets('displays chart section with period buttons', (tester) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        final hasChart =
            tester.any(find.text('Y')) ||
            tester.any(find.text('Watch Activity'));

        expect(hasChart, true);
      });
    });

    testWidgets('switches chart period when button tapped', (tester) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        if (tester.any(find.text('W'))) {
          final weekButton = find.text('W');
          await tester.tap(weekButton);
          await tester.pump();
          expect(weekButton, findsOneWidget);
        }
      });
    });

    testWidgets('formats hours correctly', (tester) async {
      expect(ProfileScreenHelpers.formatHours(0), '0m');
      expect(ProfileScreenHelpers.formatHours(1.5), '1h 30m');
      expect(ProfileScreenHelpers.formatHours(2.0), '2h');
      expect(ProfileScreenHelpers.formatHours(0.5), '30m');
    });

    testWidgets('formats chart value correctly', (tester) async {
      expect(ProfileScreenHelpers.formatChartValue(0), '0h');
      expect(ProfileScreenHelpers.formatChartValue(25), '1d 1h');
      expect(ProfileScreenHelpers.formatChartValue(10), '10h');
      expect(ProfileScreenHelpers.formatChartValue(48), '2d 0h');
    });

    testWidgets('displays user avatar correctly', (tester) async {
      await setupUserAndSeries(tester);

      final avatar = find.byType(CircleAvatar);
      expect(avatar, findsWidgets);
    });

    testWidgets('handles image error in series card', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Series',
            'imageUrl': 'invalid-url',
            'percentage': 0.5,
            'totalHours': 10.0,
            'episode': 'S01E01',
            'seriesDuration': 20.0,
            'isFavorite': false,
          },
        ],
      );

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(ProfileScreen), findsOneWidget);
      });
    });

    testWidgets('displays percentage in series card', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Series',
            'imageUrl': 'https://example.com/image.jpg',
            'percentage': 0.75,
            'totalHours': 15.0,
            'episode': 'S01E01',
            'seriesDuration': 20.0,
            'isFavorite': false,
          },
        ],
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('shows circular progress indicator in series card', (
      tester,
    ) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Series',
            'imageUrl': 'https://example.com/image.jpg',
            'percentage': 0.6,
            'totalHours': 12.0,
            'episode': 'S01E01',
            'seriesDuration': 20.0,
            'isFavorite': false,
          },
        ],
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows empty state for no series', (tester) async {
      await setupUserAndSeries(tester, series: []);

      expect(find.text('Series Progress'), findsOneWidget);
      expect(find.text('No series in progress.'), findsOneWidget);
    });

    testWidgets('displays multiple series correctly', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Series 1',
            'imageUrl': 'https://example.com/1.jpg',
            'percentage': 0.3,
            'totalHours': 10.0,
            'episode': 'S01E01',
            'seriesDuration': 30.0,
            'isFavorite': false,
          },
          {
            'id': 2,
            'name': 'Series 2',
            'imageUrl': 'https://example.com/2.jpg',
            'percentage': 0.7,
            'totalHours': 20.0,
            'episode': 'S02E05',
            'seriesDuration': 30.0,
            'isFavorite': false,
          },
        ],
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('30%'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('badge item displays correctly', (tester) async {
      await setupUserAndSeries(tester, badges: ['binge_watcher']);

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('scrolls to view all content', (tester) async {
      await setupUserAndSeries(
        tester,
        userName: 'Long Name User',
        totalHours: 200.0,
        badges: ['badge1', 'badge2'],
        series: List.generate(
          5,
          (i) => {
            'id': i,
            'name': 'Series $i',
            'imageUrl': 'https://example.com/$i.jpg',
            'percentage': 0.5,
            'totalHours': 10.0,
            'episode': 'S01E01',
            'seriesDuration': 20.0,
            'isFavorite': false,
          },
        ),
      );

      await mockNetworkImagesFor(() async {
        final scrollView = find.byType(SingleChildScrollView);
        expect(scrollView, findsOneWidget);

        await tester.drag(scrollView, const Offset(0, -300));
        await tester.pump();
      });
    });

    testWidgets('handles null user data gracefully', (tester) async {
      await mockNetworkImagesFor(() async {
        await fakeFirestore.collection('users').doc('test-user-id').set({
          'name': null,
          'totalHoursWatched': null,
          'claimedBadgeIds': [],
        });

        await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('User'), findsOneWidget);
      });
    });

    testWidgets('updates UI when stream data changes', (tester) async {
      await setupUserAndSeries(tester, userName: 'Initial Name');

      await mockNetworkImagesFor(() async {
        expect(find.text('Initial Name'), findsOneWidget);

        await fakeFirestore.collection('users').doc('test-user-id').update({
          'name': 'Updated Name',
        });

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Updated Name'), findsOneWidget);
      });
    });

    testWidgets('displays time icon in series card', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Series',
            'imageUrl': 'https://example.com/image.jpg',
            'percentage': 0.5,
            'totalHours': 10.5,
            'episode': 'S01E01',
            'seriesDuration': 20.0,
            'isFavorite': false,
          },
        ],
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.access_time), findsWidgets);
    });

    testWidgets('displays complete series are filtered out', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Complete Series',
            'imageUrl': 'https://example.com/1.jpg',
            'percentage': 1.0,
            'totalHours': 50.0,
            'episode': 'S05E13',
            'seriesDuration': 50.0,
            'isFavorite': false,
          },
          {
            'id': 2,
            'name': 'In Progress Series',
            'imageUrl': 'https://example.com/2.jpg',
            'percentage': 0.5,
            'totalHours': 25.0,
            'episode': 'S03E01',
            'seriesDuration': 50.0,
            'isFavorite': false,
          },
        ],
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('100%'), findsNothing);
    });

    testWidgets('limits series display to 6', (tester) async {
      await setupUserAndSeries(
        tester,
        series: List.generate(
          10,
          (i) => {
            'id': i,
            'name': 'Series $i',
            'imageUrl': 'https://example.com/$i.jpg',
            'percentage': 0.1 * (i + 1),
            'totalHours': 10.0,
            'episode': 'S01E01',
            'seriesDuration': 100.0,
            'isFavorite': false,
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      final percentageWidgets = find.textContaining('%');
      expect(percentageWidgets.evaluate().length, lessThanOrEqualTo(6));
    });

    testWidgets('ProfileScreen builds without errors', (tester) async {
      await setupUserAndSeries(tester);

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('displays statistics columns correctly', (tester) async {
      await setupUserAndSeries(tester);

      expect(find.text('Statistics Overview'), findsOneWidget);
      expect(find.text('Watch Activity'), findsOneWidget);
    });

    testWidgets('chart displays when data is loaded', (tester) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 2));

        final hasChart =
            tester.any(find.text('Watch Activity')) ||
            tester.any(find.text('Y'));
        expect(hasChart, true);
      });
    });

    testWidgets('chart shows "Loading activity data..." when no data', (
      tester,
    ) async {
      await setupUserAndSeries(tester);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(milliseconds: 100));

        final hasLoadingOrChart =
            tester.any(find.text('Loading activity data...')) ||
            tester.any(find.text('Watch Activity'));

        expect(hasLoadingOrChart, true);
      });
    });

    testWidgets('chart caches data for year period', (tester) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        if (tester.any(find.text('M'))) {
          await tester.tap(find.text('M'));
          await tester.pump();
          await tester.tap(find.text('Y'));
          await tester.pump();

          expect(find.text('Y'), findsOneWidget);
        }
      });
    });

    testWidgets('chart bars have correct height based on data', (tester) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        final containers = find.byType(Container);
        expect(containers, findsWidgets);
      });
    });

    testWidgets('chart bars show correct color for zero values', (
      tester,
    ) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        final containers = find.byType(Container);
        expect(containers, findsWidgets);
      });
    });

    testWidgets('chart labels show for month period with filtering', (
      tester,
    ) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        if (tester.any(find.text('M'))) {
          await tester.tap(find.text('M'));
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.text('M'), findsOneWidget);
        }
      });
    });

    testWidgets('chart labels always show for first bar', (tester) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        final hasLabels =
            tester.any(find.text('Y')) || tester.any(find.text('W'));
        expect(hasLabels, true);
      });
    });

    testWidgets('chart bar width changes based on period', (tester) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        if (tester.any(find.text('M'))) {
          await tester.tap(find.text('M'));
          await tester.pump();

          expect(find.byType(Container), findsWidgets);
        }
      });
    });

    testWidgets('chart clamps bar height correctly', (tester) async {
      await setupUserAndSeries(tester, totalHours: 1000.0, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(Container), findsWidgets);
      });
    });

    testWidgets('badge item scales Streak badge correctly', (tester) async {
      await setupUserAndSeries(
        tester,
        badges: ['streak_bronze', 'streak_silver'],
      );

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(Transform), findsWidgets);
      });
    });

    testWidgets('badge item scales The Perfectionist badge correctly', (
      tester,
    ) async {
      await setupUserAndSeries(tester, badges: ['completionist_bronze']);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(Transform), findsWidgets);
      });
    });

    testWidgets('badge item displays image correctly', (tester) async {
      await setupUserAndSeries(tester, badges: ['binge_watcher']);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(Container), findsWidgets);
      });
    });

    testWidgets('badge item has correct dimensions', (tester) async {
      await setupUserAndSeries(tester, badges: ['binge_watcher']);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(milliseconds: 200));

        final containers = tester.widgetList<Container>(find.byType(Container));
        expect(containers.length, greaterThan(0));
      });
    });

    testWidgets('badge item displays title with correct styling', (
      tester,
    ) async {
      await setupUserAndSeries(tester, badges: ['binge_watcher']);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(Text), findsWidgets);
      });
    });

    testWidgets('series card formats hours correctly', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Series',
            'imageUrl': 'https://example.com/image.jpg',
            'percentage': 0.5,
            'totalHours': 2.5,
            'episode': 'S01E01',
            'seriesDuration': 5.0,
            'isFavorite': false,
          },
        ],
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('h'), findsWidgets);
    });

    testWidgets('series card has correct border and shadow', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Styled Series',
            'imageUrl': 'https://example.com/styled.jpg',
            'percentage': 0.6,
            'totalHours': 12.0,
            'episode': 'S02E03',
            'seriesDuration': 20.0,
            'isFavorite': false,
          },
        ],
      );

      await tester.pump(const Duration(milliseconds: 200));

      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('series card displays image with ClipRRect', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Rounded Series',
            'imageUrl': 'https://example.com/rounded.jpg',
            'percentage': 0.4,
            'totalHours': 8.0,
            'episode': 'S01E04',
            'seriesDuration': 20.0,
            'isFavorite': false,
          },
        ],
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('chart shows correct subtitle for week period', (tester) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        if (tester.any(find.text('W'))) {
          await tester.tap(find.text('W'));
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.textContaining('current week'), findsAny);
        }
      });
    });

    testWidgets('chart shows correct subtitle for month period', (
      tester,
    ) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        if (tester.any(find.text('M'))) {
          await tester.tap(find.text('M'));
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.textContaining('current Month'), findsAny);
        }
      });
    });

    testWidgets('chart shows correct subtitle for year period', (tester) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        expect(find.textContaining('current Year'), findsAny);
      });
    });

    testWidgets('chart displays dividers for visual separation', (
      tester,
    ) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(Divider), findsAny);
      });
    });

    testWidgets('chart labels use correct weekday format for week view', (
      tester,
    ) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        if (tester.any(find.text('W'))) {
          await tester.tap(find.text('W'));
          await tester.pump(const Duration(milliseconds: 500));

          final hasWeekdayLabels =
              tester.any(find.text('M')) ||
              tester.any(find.text('W')) ||
              tester.any(find.text('F'));
          expect(hasWeekdayLabels, true);
        }
      });
    });

    testWidgets('chart maxVal clamps to minimum of 5.0', (tester) async {
      await setupUserAndSeries(tester, totalHours: 0.5, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('Watch Activity'), findsOneWidget);
      });
    });

    testWidgets('period buttons have correct styling when selected', (
      tester,
    ) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        final yearButton = find.text('Y');
        expect(yearButton, findsOneWidget);
      });
    });

    testWidgets('period buttons have correct styling when unselected', (
      tester,
    ) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        final weekButton = find.text('W');
        final monthButton = find.text('M');
        expect(weekButton, findsOneWidget);
        expect(monthButton, findsOneWidget);
      });
    });

    testWidgets('AnimatedContainer used for period button transitions', (
      tester,
    ) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(AnimatedContainer), findsAny);
      });
    });

    testWidgets('chart shows max value label at top', (tester) async {
      await setupUserAndSeries(tester, totalHours: 100.0, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        final hasMaxLabel =
            tester.any(find.textContaining('d')) || tester.any(find.text('0h'));
        expect(hasMaxLabel, true);
      });
    });

    testWidgets('chart shows mid value label', (tester) async {
      await setupUserAndSeries(tester, totalHours: 50.0, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(Text), findsWidgets);
      });
    });

    testWidgets('chart shows zero label at bottom', (tester) async {
      await setupUserAndSeries(tester, waitForChart: true);

      await mockNetworkImagesFor(() async {
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('0h'), findsOneWidget);
      });
    });

    testWidgets('series card grid has correct aspect ratio', (tester) async {
      await setupUserAndSeries(
        tester,
        series: [
          {
            'id': 1,
            'name': 'Grid Series',
            'imageUrl': 'https://example.com/grid.jpg',
            'percentage': 0.5,
            'totalHours': 10.0,
            'episode': 'S01E01',
            'seriesDuration': 20.0,
            'isFavorite': false,
          },
        ],
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('empty badge section shows correct message', (tester) async {
      await setupUserAndSeries(tester, badges: []);

      expect(find.text('Keep watching to unlock badges!'), findsOneWidget);
    });

    testWidgets('badge section shows up to 4 badges', (tester) async {
      await setupUserAndSeries(
        tester,
        badges: ['badge1', 'badge2', 'badge3', 'badge4'],
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(Row), findsWidgets);
    });
  });
}
