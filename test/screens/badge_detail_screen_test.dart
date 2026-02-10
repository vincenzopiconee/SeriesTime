import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:seriestime/data/badge_definitions.dart';
import 'package:seriestime/models/user.dart';
import 'package:seriestime/screens/badge_detail_screen.dart';

void main() {
  setUp(() {
    AppData.currentUser = User(
      name: 'Test User',
      totalHoursWatched: 100.0,
      maxConsecutiveHours: 10.0,
      weekendHours: 25.0,
      nightOwlHours: 15.0,
      uniqueGenresCount: 8,
      claimedBadgeIds: [BadgeDefinitions.marathonerMilestones[0].id],
      photoUrl: null,
      seriesStreak: 5,
      lastViewDate: DateTime.now(),
    );
  });

  tearDown(() {
    AppData.currentUser = null;
  });

  group('BadgeDetailScreen - UI Components', () {
    testWidgets('displays current badge image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 50.0,
            unit: 'h',
          ),
        ),
      );

      expect(find.byType(Image), findsWidgets);
      expect(find.text('Total Progress'), findsOneWidget);
    });

    testWidgets('shows "How it works" section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 50.0,
            unit: 'h',
          ),
        ),
      );

      expect(find.text('How it works'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('displays Mission Milestones section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 50.0,
            unit: 'h',
          ),
        ),
      );

      expect(find.text('Mission Milestones'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });
  });

  group('BadgeDetailScreen - Value Formatting', () {
    testWidgets('formats hours correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 5.5,
            unit: 'h',
          ),
        ),
      );

      expect(find.text('5h 30m'), findsOneWidget);
    });

    testWidgets('formats series count correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'The Perfectionist',
            milestones: BadgeDefinitions.completionistMilestones,
            currentValue: 10.0,
            unit: 'S',
          ),
        ),
      );

      expect(find.text('10 Series'), findsOneWidget);
    });

    testWidgets('formats genres count correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Genre Explorer',
            milestones: BadgeDefinitions.genreMilestones,
            currentValue: 8.0,
            unit: 'G',
          ),
        ),
      );

      expect(find.text('8 Genres'), findsOneWidget);
    });

    testWidgets('formats days correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Streak',
            milestones: BadgeDefinitions.streakMilestones,
            currentValue: 5.0,
            unit: 'd',
          ),
        ),
      );

      expect(find.text('5d'), findsOneWidget);
    });
  });

  group('BadgeDetailScreen - Badge Categories', () {
    testWidgets('shows correct description for Marathoner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 50.0,
            unit: 'h',
          ),
        ),
      );

      expect(find.textContaining('total lifetime watch time'), findsOneWidget);
    });

    testWidgets('shows correct description for Pure Obsession', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Pure Obsession',
            milestones: BadgeDefinitions.obsessionMilestones,
            currentValue: 10.0,
            unit: 'h',
          ),
        ),
      );

      expect(
        find.textContaining('longest consecutive binge-watching'),
        findsOneWidget,
      );
    });

    testWidgets('shows correct description for Streak', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Streak',
            milestones: BadgeDefinitions.streakMilestones,
            currentValue: 5.0,
            unit: 'd',
          ),
        ),
      );

      expect(find.textContaining('consecutive days'), findsOneWidget);
    });
  });

  group('BadgeDetailScreen - Special Scaling', () {
    testWidgets('applies special scaling for Streak badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Streak',
            milestones: BadgeDefinitions.streakMilestones,
            currentValue: 5.0,
            unit: 'd',
          ),
        ),
      );

      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Transform),
            )
            .first,
      );

      expect(transform, isNotNull);
    });

    testWidgets('applies special scaling for Perfectionist badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'The Perfectionist',
            milestones: BadgeDefinitions.completionistMilestones,
            currentValue: 10.0,
            unit: 'S',
          ),
        ),
      );

      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Transform),
            )
            .first,
      );

      expect(transform, isNotNull);
    });
  });

  group('BadgeDetailScreen - Milestone Display', () {
    testWidgets('shows unlocked milestone with check icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 50.0,
            unit: 'h',
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('displays all milestones', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 50.0,
            unit: 'h',
          ),
        ),
      );

      expect(
        find.byType(LinearProgressIndicator),
        findsNWidgets(BadgeDefinitions.marathonerMilestones.length),
      );
    });

    testWidgets('shows level labels for milestones', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 50.0,
            unit: 'h',
          ),
        ),
      );

      expect(find.textContaining('Level:'), findsWidgets);
    });
  });

  group('BadgeDetailScreen - Edge Cases', () {
    testWidgets('handles zero current value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 0.0,
            unit: 'h',
          ),
        ),
      );

      expect(find.text('0m'), findsOneWidget);
    });

    testWidgets('handles null claimed badges', (tester) async {
      AppData.currentUser = null;

      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 50.0,
            unit: 'h',
          ),
        ),
      );

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
    });

    testWidgets('handles scrolling with many milestones', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BadgeDetailScreen(
            categoryTitle: 'Marathoner',
            milestones: BadgeDefinitions.marathonerMilestones,
            currentValue: 50.0,
            unit: 'h',
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
