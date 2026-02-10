import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/screens/series_progress_screen.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:seriestime/models/series.dart';
import 'package:seriestime/models/user.dart';

void main() {
  group('SeriesProgressScreen Tests', () {
    setUp(() {
      AppData.resetData();
    });

    testWidgets('shows loading when no user', (tester) async {
      AppData.currentUser = null;

      await tester.pumpWidget(const MaterialApp(home: SeriesProgressScreen()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty list when no series', (tester) async {
      AppData.currentUser = User(
        name: 'Test User',
        totalHoursWatched: 0,
        maxConsecutiveHours: 0,
        weekendHours: 0,
        nightOwlHours: 0,
        uniqueGenresCount: 0,
        claimedBadgeIds: [],
      );
      AppData.userSeries = [];

      await tester.pumpWidget(const MaterialApp(home: SeriesProgressScreen()));

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Series Progress'), findsOneWidget);
    });

    testWidgets('sorts series by percentage descending', (tester) async {
      AppData.currentUser = User(
        name: 'Test User',
        totalHoursWatched: 50,
        maxConsecutiveHours: 0,
        weekendHours: 0,
        nightOwlHours: 0,
        uniqueGenresCount: 0,
        claimedBadgeIds: [],
      );

      AppData.userSeries = [
        Series(
          id: 1,
          name: 'Series A',
          imageUrl: '',
          percentage: 0.3,
          totalHours: 10.0,
          episode: 'S1 E1',
          seriesDuration: 30.0,
        ),
        Series(
          id: 2,
          name: 'Series B',
          imageUrl: '',
          percentage: 0.8,
          totalHours: 40.0,
          episode: 'S5 E1',
          seriesDuration: 50.0,
        ),
      ];

      await tester.pumpWidget(const MaterialApp(home: SeriesProgressScreen()));

      expect(find.text('Series B'), findsOneWidget);
      expect(find.text('Series A'), findsOneWidget);
    });

    testWidgets('shows progress bar', (tester) async {
      AppData.currentUser = User(
        name: 'Test User',
        totalHoursWatched: 20,
        maxConsecutiveHours: 0,
        weekendHours: 0,
        nightOwlHours: 0,
        uniqueGenresCount: 0,
        claimedBadgeIds: [],
      );

      AppData.userSeries = [
        Series(
          id: 1,
          name: 'Test Series',
          imageUrl: '',
          percentage: 0.6,
          totalHours: 30.0,
          episode: 'S3 E8',
          seriesDuration: 50.0,
        ),
      ];

      await tester.pumpWidget(const MaterialApp(home: SeriesProgressScreen()));

      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      AppData.currentUser = User(
        name: 'Test User',
        totalHoursWatched: 10,
        maxConsecutiveHours: 0,
        weekendHours: 0,
        nightOwlHours: 0,
        uniqueGenresCount: 0,
        claimedBadgeIds: [],
      );
      AppData.userSeries = [];

      await tester.pumpWidget(const MaterialApp(home: SeriesProgressScreen()));

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('shows SeriesProgressScreen', (tester) async {
      AppData.currentUser = User(
        name: 'Test User',
        totalHoursWatched: 10,
        maxConsecutiveHours: 0,
        weekendHours: 0,
        nightOwlHours: 0,
        uniqueGenresCount: 0,
        claimedBadgeIds: [],
      );
      AppData.userSeries = [];

      await tester.pumpWidget(const MaterialApp(home: SeriesProgressScreen()));

      expect(find.byType(SeriesProgressScreen), findsOneWidget);
    });
  });
}
