import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  group('DefaultFirebaseOptions Tests', () {
    test('Verifica configurazione Web', () {
      const options = DefaultFirebaseOptions.web;
      expect(options.apiKey, isNotEmpty);
      expect(options.projectId, equals('seriestime-data'));
    });

    test('Verifica configurazione Android', () {
      const options = DefaultFirebaseOptions.android;
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, contains('android'));
    });

    test('Verifica configurazione iOS/macOS', () {
      const options = DefaultFirebaseOptions.ios;
      expect(options.iosBundleId, equals('com.example.seriestime'));
    });

    test('Verifica il getter currentPlatform', () {
      try {
        final options = DefaultFirebaseOptions.currentPlatform;
        expect(options, isA<FirebaseOptions>());
      } catch (e) {
        expect(e, isA<UnsupportedError>());
      }
    });
  });
}
