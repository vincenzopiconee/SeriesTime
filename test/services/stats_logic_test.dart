import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/services/stats_logic.dart';
import 'package:seriestime/models/user.dart';
import 'package:seriestime/models/series.dart';
import 'package:seriestime/models/user_badge.dart';

void main() {
  group('StatsLogic Unit Tests - Calcolo Badge e Traguardi', () {
    // Creiamo un utente di test con diverse statistiche
    final testUser = User(
      name: "Gianluca",
      totalHoursWatched: 150.0, // Dovrebbe avere badge Marathoner
      maxConsecutiveHours: 5.0, // Dovrebbe avere badge Obsession
      weekendHours: 12.0,
      nightOwlHours: 3.0,
      uniqueGenresCount: 10,
      seriesStreak: 5,
      claimedBadgeIds: [],
    );

    test('getMarathonerTarget deve restituire il traguardo corretto', () {
      final target = StatsLogic.getMarathonerTarget(40.0);
      // Se ho guardato 40 ore, il prossimo traguardo non deve essere quello da 10
      expect(target.targetHours, greaterThan(10.0));
      expect(target.title, equals("Marathoner"));
    });

    test(
      'generateUserBadges deve calcolare correttamente i badge guadagnati',
      () {
        final badges = StatsLogic.generateUserBadges(testUser, []);

        // Verifichiamo che l'utente con 150 ore abbia guadagnato dei badge
        expect(badges.isNotEmpty, isTrue);

        // Verifichiamo che i badge appartengano alle categorie corrette
        bool hasMarathoner = badges.any((b) => b.title == "Marathoner");
        expect(hasMarathoner, isTrue);
      },
    );

    test('getAllUnclaimedBadges deve filtrare i badge già riscattati', () {
      // Simuliamo che l'utente abbia già riscattato il primo badge Marathoner (id: "m1")
      final userWithClaimed = User(
        name: "Test",
        totalHoursWatched: 200.0,
        claimedBadgeIds: ["m1"], // Badge già preso
        maxConsecutiveHours: 0,
        weekendHours: 0,
        nightOwlHours: 0,
        uniqueGenresCount: 0,
        seriesStreak: 0,
      );

      final unclaimed = StatsLogic.getAllUnclaimedBadges(userWithClaimed, []);

      // Il badge "m1" non deve apparire nella lista dei "da riscattare"
      expect(unclaimed.any((b) => b.id == "m1"), isFalse);
    });

    test('getGenreTarget deve gestire correttamente il conteggio generi', () {
      final target = StatsLogic.getGenreTarget(5);
      expect(target.title, equals("Genre Explorer"));
      expect(target.targetHours, isNotNull);
    });

    test('generateUserBadges con utente null deve restituire lista vuota', () {
      final badges = StatsLogic.generateUserBadges(null, []);
      expect(badges, isEmpty);
    });
  });
}
