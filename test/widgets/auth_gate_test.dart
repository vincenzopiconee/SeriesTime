import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:seriestime/widgets/auth_gate.dart';
import 'package:seriestime/screens/login_screen.dart';
import 'package:seriestime/screens/main_wrapper_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FirebasePlatform.instance = MockFirebasePlatform();
    await Firebase.initializeApp();
  });

  group('AuthGate Tests', () {
    testWidgets('AuthGate mostra LoginScreen quando l\'utente non è loggato', (
      WidgetTester tester,
    ) async {
      final auth = MockFirebaseAuth(signedIn: false);
      AuthGate.auth = auth;

      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('AuthGate mostra MainWrapper quando l\'utente è loggato', (
      WidgetTester tester,
    ) async {
      final auth = MockFirebaseAuth(signedIn: true);
      AuthGate.auth = auth;

      await tester.pumpWidget(const MaterialApp(home: AuthGate()));

      await tester.pump();

      await tester.pumpAndSettle();

      expect(find.byType(MainWrapper), findsOneWidget);
    });
  });
}

class MockFirebasePlatform extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return FirebaseAppPlatform(
      name ?? '[DEFAULT]',
      const FirebaseOptions(
        apiKey: '123',
        appId: '123',
        messagingSenderId: '123',
        projectId: '123',
      ),
    );
  }

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return FirebaseAppPlatform(
      name,
      const FirebaseOptions(
        apiKey: '123',
        appId: '123',
        messagingSenderId: '123',
        projectId: '123',
      ),
    );
  }
}
