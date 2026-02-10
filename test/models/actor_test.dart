import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/actor.dart'; 

void main() {
  group('Actor Model Tests', () {
    test('Creazione Actor tramite costruttore standard', () {
      final actor = Actor(
        name: "Bryan Cranston",
        characterName: "Walter White",
        profileUrl: "https://image.tmdb.org/t/p/w185/path.jpg",
      );

      expect(actor.name, "Bryan Cranston");
      expect(actor.characterName, "Walter White");
      expect(actor.profileUrl, contains("/path.jpg"));
    });

    test('Actor.fromJson deve mappare correttamente i dati di TMDB', () {
      final Map<String, dynamic> json = {
        'name': 'Aaron Paul',
        'character': 'Jesse Pinkman',
        'profile_path': '/abc.jpg',
      };

      final actor = Actor.fromJson(json);

      expect(actor.name, 'Aaron Paul');
      expect(actor.characterName, 'Jesse Pinkman');
      expect(actor.profileUrl, 'https://image.tmdb.org/t/p/w185/abc.jpg');
    });

    test('Actor.fromJson deve gestire i valori null o mancanti', () {
      final Map<String, dynamic> json = {
        'name': null,
        'character': null,
        'profile_path': null,
      };

      final actor = Actor.fromJson(json);

      expect(actor.name, "Unknown");
      expect(actor.characterName, "Unknown");
      expect(actor.profileUrl, isNull);
    });
  });
}
