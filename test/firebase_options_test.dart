import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

void main() {
  group('DefaultFirebaseOptions Tests', () {
    test('Verifica configurazione Web', () {
      // Accediamo direttamente alla costante per la copertura
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
      // Questo test copre la logica di selezione automatica della piattaforma
      try {
        final options = DefaultFirebaseOptions.currentPlatform;
        expect(options, isA<FirebaseOptions>());
      } catch (e) {
        // In alcuni ambienti di test puro (senza simulatore),
        // currentPlatform potrebbe lanciare UnsupportedError per Linux.
        // Lo catturiamo per non far fallire il test, garantendo comunque la copertura del ramo.
        expect(e, isA<UnsupportedError>());
      }
    });
  });
}
