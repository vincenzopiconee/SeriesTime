import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/watch_provider.dart';

void main() {
  group('WatchProvider Model Tests', () {
    test('Creazione WatchProvider tramite costruttore standard', () {
      final provider = WatchProvider(
        providerName: "Netflix",
        logoUrl: "https://image.tmdb.org/t/p/w92/logo.jpg",
      );

      expect(provider.providerName, "Netflix");
      expect(provider.logoUrl, contains("/logo.jpg"));
    });

    test(
      'WatchProvider.fromJson deve costruire correttamente l\'URL del logo',
      () {
        final Map<String, dynamic> json = {
          'provider_name': 'Disney Plus',
          'logo_path': '/disney_logo.png',
        };

        final provider = WatchProvider.fromJson(json);

        expect(provider.providerName, 'Disney Plus');
        // Verifica che il prefisso TMDB per le icone (w92) sia corretto
        expect(
          provider.logoUrl,
          'https://image.tmdb.org/t/p/w92/disney_logo.png',
        );
      },
    );

    test(
      'WatchProvider.fromJson deve gestire il nome mancante con una stringa vuota',
      () {
        final Map<String, dynamic> json = {
          'provider_name': null,
          'logo_path': '/path.png',
        };

        final provider = WatchProvider.fromJson(json);

        expect(provider.providerName, "");
        expect(provider.logoUrl, isNotNull);
      },
    );
  });
}
