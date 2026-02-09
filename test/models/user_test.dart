import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('Creazione User e verifica integrità dati iniziali', () {
      final now = DateTime.now();
      final user = User(
        name: "Gianluca",
        totalHoursWatched: 150.5,
        maxConsecutiveHours: 5.0,
        weekendHours: 20.0,
        nightOwlHours: 10.0,
        uniqueGenresCount: 4,
        claimedBadgeIds: ["mbase", "sbase"],
        photoUrl: "https://example.com/photo.jpg",
        seriesStreak: 12,
        lastViewDate: now,
      );

      expect(user.name, "Gianluca");
      expect(user.totalHoursWatched, 150.5);
      expect(user.maxConsecutiveHours, 5.0);
      expect(user.uniqueGenresCount, 4);
      expect(user.claimedBadgeIds, containsAll(["mbase", "sbase"]));
      expect(user.photoUrl, "https://example.com/photo.jpg");
      expect(user.seriesStreak, 12);
      expect(user.lastViewDate, now);
    });

    test('Verifica mutabilità dei campi (Streak e Badge)', () {
      final user = User(
        name: "Test User",
        totalHoursWatched: 0.0,
        maxConsecutiveHours: 0.0,
        weekendHours: 0.0,
        nightOwlHours: 0.0,
        uniqueGenresCount: 0,
        claimedBadgeIds: [], // Nota: non usare const [] se devi modificarlo
      );

      // Simuliamo l'aggiornamento dei dati
      user.seriesStreak = 1;
      user.claimedBadgeIds = ["new_badge"];
      user.lastViewDate = DateTime(2025, 1, 1);

      expect(user.seriesStreak, 1);
      expect(user.claimedBadgeIds, contains("new_badge"));
      expect(user.lastViewDate, isNotNull);
    });

    test('Verifica valori di default del costruttore', () {
      final user = User(
        name: "Minimal User",
        totalHoursWatched: 10.0,
        maxConsecutiveHours: 1.0,
        weekendHours: 2.0,
        nightOwlHours: 0.5,
        uniqueGenresCount: 2,
      );

      // Verifichiamo i parametri opzionali con default
      expect(user.claimedBadgeIds, isEmpty);
      expect(user.seriesStreak, 0);
      expect(user.photoUrl, isNull);
      expect(user.lastViewDate, isNull);
    });
  });
}
