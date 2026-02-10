import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/screens/main_wrapper_screen.dart';
import 'package:seriestime/screens/explore_screen.dart';
import 'package:seriestime/screens/my_series_screen.dart';
import 'package:seriestime/screens/binge_mode_screen.dart';
import 'package:seriestime/screens/profile_screen.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('MainWrapper - Complete Coverage', () {
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
          '{"results": [{"id": 1, "name": "Test Show", "poster_path": "/test.jpg", "vote_average": 8.0, "first_air_date": "2020-01-01", "origin_country": ["US"], "genre_ids": [18], "overview": "Test"}]}',
          200,
        );
      });
    });

    testWidgets('shows MainWrapper', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MainWrapper(httpClient: mockHttpClient)),
      );
      await tester.pump();

      expect(find.byType(MainWrapper), findsOneWidget);
    });

    testWidgets('navigates to My Series screen', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MainWrapper(httpClient: mockHttpClient)),
      );
      await tester.pump();

      await tester.tap(find.text("My Series"));
      await tester.pump();

      expect(find.byType(MySeriesScreen), findsOneWidget);
    });

    testWidgets('navigates to Binge Mode screen', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MainWrapper(httpClient: mockHttpClient)),
      );
      await tester.pump();

      await tester.tap(find.text("Binge Mode"));
      await tester.pump();

      expect(find.byType(BingeModeScreen), findsOneWidget);
    });

    testWidgets('navigates to Profile screen', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MainWrapper(httpClient: mockHttpClient)),
      );
      await tester.pump();

      await tester.tap(find.text("Profile"));
      await tester.pump();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('handles user data stream updates', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MainWrapper(httpClient: mockHttpClient)),
      );
      await tester.pump();

      await fakeFirestore.collection('users').doc('test-user-id').update({
        'claimedBadgeIds': ['marathoner_1'],
      });
      await tester.pump();

      expect(find.byType(MainWrapper), findsOneWidget);
    });

    testWidgets('returns to Explore when tapping', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MainWrapper(httpClient: mockHttpClient)),
      );
      await tester.pump();

      await tester.tap(find.text("Profile"));
      await tester.pump();

      expect(find.byType(ProfileScreen), findsOneWidget);

      await tester.tap(find.text("Explore").last);
      await tester.pump();

      expect(find.byType(ExploreScreen), findsOneWidget);
    });

    testWidgets('handles null user data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: MainWrapper(httpClient: mockHttpClient)),
      );
      await tester.pump();

      expect(find.byType(MainWrapper), findsOneWidget);
    });

    testWidgets('navigates through all screens', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MainWrapper(httpClient: mockHttpClient)),
      );
      await tester.pump();

      await tester.tap(find.text("My Series"));
      await tester.pump();
      expect(find.byType(MySeriesScreen), findsOneWidget);

      await tester.tap(find.text("Binge Mode"));
      await tester.pump();
      expect(find.byType(BingeModeScreen), findsOneWidget);

      await tester.tap(find.text("Profile"));
      await tester.pump();
      expect(find.byType(ProfileScreen), findsOneWidget);

      await tester.tap(find.text("Explore").last);
      await tester.pump();
      expect(find.byType(ExploreScreen), findsOneWidget);
    });

    testWidgets('shows navigation widgets', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MainWrapper(httpClient: mockHttpClient)),
      );
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('changes screen on tap', (tester) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'claimedBadgeIds': [],
      });

      await tester.pumpWidget(
        MaterialApp(home: MainWrapper(httpClient: mockHttpClient)),
      );
      await tester.pump();

      await tester.tap(find.text("My Series"));
      await tester.pump();

      await tester.tap(find.text("Explore").last);
      await tester.pump();

      expect(find.byType(ExploreScreen), findsOneWidget);
    });
  });
}
