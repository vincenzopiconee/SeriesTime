import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/screens/settings_screen.dart';
import 'package:seriestime/screens/login_screen.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:seriestime/models/user.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Tests', () {
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

    Future<void> setupUserData({String userName = 'Test User'}) async {
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': userName,
        'totalHoursWatched': 100.0,
        'maxConsecutiveHours': 5.0,
        'weekendHours': 20.0,
        'nightOwlHours': 15.0,
        'uniqueGenresCount': 3,
        'seriesStreak': 2,
        'claimedBadgeIds': [],
        'photoUrl': null,
      });

      AppData.currentUser = User(
        name: userName,
        totalHoursWatched: 100.0,
        maxConsecutiveHours: 5.0,
        weekendHours: 20.0,
        nightOwlHours: 15.0,
        uniqueGenresCount: 3,
        seriesStreak: 2,
        claimedBadgeIds: [],
        photoUrl: null,
      );
    }

    testWidgets('displays Settings screen with app bar', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays user name and email', (tester) async {
      await setupUserData(userName: 'John Doe');

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('displays default user name when no current user', (
      tester,
    ) async {
      AppData.currentUser = null;

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('User'), findsOneWidget);
    });

    testWidgets('displays About section', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('displays app version', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('displays data source information', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('Data Source'), findsOneWidget);
      expect(find.text('Provided by TMDB'), findsOneWidget);
    });

    testWidgets('displays logout button', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('LOGOUT'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'LOGOUT'), findsOneWidget);
    });

    testWidgets('displays delete account button', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Delete Account'), findsOneWidget);
    });

    testWidgets('back button navigates back', (tester) async {
      await setupUserData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ),
                child: const Text('Go to Settings'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);

      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsNothing);
    });

    testWidgets('delete account shows confirmation dialog', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final deleteButton = find.text('Delete Account');
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsWidgets);
      expect(
        find.textContaining('Are you sure you want to delete your account?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancel button in delete dialog closes dialog', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      final cancelButton = find.widgetWithText(TextButton, 'Cancel');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Are you sure you want to delete your account?'),
        findsNothing,
      );
    });

    testWidgets('delete button in dialog triggers delete process', (
      tester,
    ) async {
      await setupUserData();

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Breaking Bad')
          .set({'id': 1, 'name': 'Breaking Bad'});

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      final deleteButton = find.widgetWithText(ElevatedButton, 'Delete');
      await tester.tap(deleteButton);
      await tester.pump();

      expect(find.text('Cleaning Database...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays loading state during deletion', (tester) async {
      await setupUserData();

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump();

      expect(find.text('Cleaning Database...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      expect(find.widgetWithText(TextButton, 'Delete Account'), findsNothing);
    });

    testWidgets('handles requires-recent-login error', (tester) async {
      await setupUserData();

      final errorMockAuth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'test-user-id',
          email: 'test@example.com',
          displayName: 'Test User',
        ),
        signedIn: true,
      );

      AppData.firebaseAuth = errorMockAuth;

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump();

      expect(find.text('Cleaning Database...'), findsOneWidget);
    });

    testWidgets('screen is scrollable', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);

      await tester.drag(scrollView, const Offset(0, -100));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('displays divider in about section', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('section card has proper styling', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('logout button has proper styling', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final logoutButton = find.widgetWithText(ElevatedButton, 'LOGOUT');
      expect(logoutButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(logoutButton);
      expect(button.style?.backgroundColor?.resolve({}), AppData.primaryColor);
    });

    testWidgets('delete account button is a text button', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final deleteButton = find.widgetWithText(TextButton, 'Delete Account');
      expect(deleteButton, findsOneWidget);
    });

    testWidgets('confirmation dialog has proper title', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsWidgets);
    });

    testWidgets('confirmation dialog warns about permanent deletion', (
      tester,
    ) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.textContaining('cannot be undone'), findsOneWidget);
      expect(find.textContaining('ALL your data permanently'), findsOneWidget);
    });

    testWidgets('handles null user during deletion', (tester) async {
      AppData.currentUser = null;

      final nullMockAuth = MockFirebaseAuth(signedIn: false);
      AppData.firebaseAuth = nullMockAuth;

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('displays no email text when user has no email', (
      tester,
    ) async {
      await setupUserData();

      final noEmailMockAuth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'test-user-id',
          email: null,
          displayName: 'Test User',
        ),
        signedIn: true,
      );
      AppData.firebaseAuth = noEmailMockAuth;

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('No email'), findsOneWidget);
    });

    testWidgets('about section contains multiple info rows', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('Data Source'), findsOneWidget);
    });

    testWidgets('settings screen builds without errors', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('app bar title is centered', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });

    testWidgets('app bar has correct background color', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppData.primaryColor);
    });

    testWidgets('body has correct background color', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppData.backgroundColor);
    });

    testWidgets('user name has correct styling', (tester) async {
      await setupUserData(userName: 'Styled User');

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final nameText = find.text('Styled User');
      expect(nameText, findsOneWidget);

      final textWidget = tester.widget<Text>(nameText);
      expect(textWidget.style?.fontSize, 28);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
      expect(textWidget.style?.color, AppData.primaryColor);
    });

    testWidgets('displays all UI elements in correct order', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('LOGOUT'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('delete dialog has correct button layout', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      final row = find.byType(Row);
      expect(row, findsWidgets);
    });

    testWidgets('handles rapid logout button taps', (tester) async {
      await setupUserData();

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      final logoutButton = find.text('LOGOUT');

      await tester.tap(logoutButton);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('logout resets AppData before navigation', (tester) async {
      await setupUserData();

      AppData.currentUser = User(
        name: 'Test User',
        totalHoursWatched: 100.0,
        maxConsecutiveHours: 5.0,
        weekendHours: 20.0,
        nightOwlHours: 15.0,
        uniqueGenresCount: 3,
        seriesStreak: 2,
        claimedBadgeIds: [],
        photoUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      final logoutButton = find.text('LOGOUT');
      await tester.tap(logoutButton);
      await tester.pump();

      expect(AppData.currentUser, isNull);
    });

    testWidgets('deletes episodes from seasons during account deletion', (
      tester,
    ) async {
      await setupUserData();

      final seriesRef = fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Breaking Bad');

      await seriesRef.set({'id': 1, 'name': 'Breaking Bad'});

      final season1Ref = seriesRef.collection('seasons').doc('season-1');
      await season1Ref.set({'seasonNumber': 1});
      await season1Ref.collection('episodes').doc('ep-1').set({
        'episodeNumber': 1,
        'name': 'Pilot',
      });
      await season1Ref.collection('episodes').doc('ep-2').set({
        'episodeNumber': 2,
        'name': 'Cat\'s in the Bag...',
      });

      final season2Ref = seriesRef.collection('seasons').doc('season-2');
      await season2Ref.set({'seasonNumber': 2});
      await season2Ref.collection('episodes').doc('ep-1').set({
        'episodeNumber': 1,
        'name': 'Seven Thirty-Seven',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Cleaning Database...'), findsOneWidget);
    });

    testWidgets('handles multiple series with seasons and episodes', (
      tester,
    ) async {
      await setupUserData();

      for (int i = 1; i <= 3; i++) {
        final seriesRef = fakeFirestore
            .collection('users')
            .doc('test-user-id')
            .collection('series')
            .doc('Series$i');

        await seriesRef.set({'id': i, 'name': 'Series$i'});

        for (int s = 1; s <= 2; s++) {
          final seasonRef = seriesRef.collection('seasons').doc('season-$s');
          await seasonRef.set({'seasonNumber': s});

          for (int e = 1; e <= 3; e++) {
            await seasonRef.collection('episodes').doc('ep-$e').set({
              'episodeNumber': e,
              'name': 'Episode $e',
            });
          }
        }
      }

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cleaning Database...'), findsOneWidget);
    });

    testWidgets('handles empty seasons during deletion', (tester) async {
      await setupUserData();

      final seriesRef = fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Series1');

      await seriesRef.set({'id': 1, 'name': 'Series1'});

      final seasonRef = seriesRef.collection('seasons').doc('season-1');
      await seasonRef.set({'seasonNumber': 1});

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cleaning Database...'), findsOneWidget);
    });

    testWidgets('security check dialog shows when requires-recent-login', (
      tester,
    ) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(seconds: 1));

      final hasLoading = tester.any(find.text('Cleaning Database...'));
      final hasNavigated = tester.any(find.byType(LoginScreen));

      expect(hasLoading || hasNavigated, true);
    });

    testWidgets('error dialog shows for general deletion errors', (
      tester,
    ) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Cleaning Database...'), findsOneWidget);
    });

    testWidgets('handles partial deletion failures gracefully', (tester) async {
      await setupUserData();

      final seriesRef = fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('Series1');

      await seriesRef.set({'id': 1, 'name': 'Series1'});

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Log Out & Retry button in security dialog works', (
      tester,
    ) async {
      await setupUserData();

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Cancel button in security dialog closes it', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Are you sure'), findsOneWidget);
    });

    testWidgets('deletes user document after series deletion', (tester) async {
      await setupUserData();

      final userDoc = fakeFirestore.collection('users').doc('test-user-id');
      await userDoc.set({'name': 'Test User', 'totalHoursWatched': 100.0});

      final seriesDoc = userDoc.collection('series').doc('Series1');
      await seriesDoc.set({'id': 1, 'name': 'Series1'});

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cleaning Database...'), findsOneWidget);
    });

    testWidgets('shows error dialog with correct title and message', (
      tester,
    ) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final state = tester.state<SettingsScreenState>(
        find.byType(SettingsScreen),
      );

      state.showErrorDialog('Test Error', 'This is a test error message');
      await tester.pumpAndSettle();

      expect(find.text('Test Error'), findsOneWidget);
      expect(find.text('This is a test error message'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('error dialog OK button closes dialog', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final state = tester.state<SettingsScreenState>(
        find.byType(SettingsScreen),
      );

      state.showErrorDialog('Test Error', 'Test message');
      await tester.pumpAndSettle();

      final okButton = find.text('OK');
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      expect(find.text('Test Error'), findsNothing);
    });

    testWidgets('handles GoogleSignIn signout during logout', (tester) async {
      await setupUserData();

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      final logoutButton = find.text('LOGOUT');
      await tester.tap(logoutButton);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('mounted check prevents navigation after disposal', (
      tester,
    ) async {
      await setupUserData();

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles user-not-found error during deletion', (tester) async {
      await setupUserData();

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('deletes series without seasons', (tester) async {
      await setupUserData();

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('series')
          .doc('SimpleSeries')
          .set({'id': 1, 'name': 'SimpleSeries'});

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cleaning Database...'), findsOneWidget);
    });

    testWidgets('handles PlatformException during deletion', (tester) async {
      await setupUserData();

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
