import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/data/badge_definitions.dart';

void main() {
  group('BadgeDefinitions Tests', () {
    test('Le liste dei badge non devono essere vuote', () {
      expect(BadgeDefinitions.marathonerMilestones.isNotEmpty, true);
      expect(BadgeDefinitions.obsessionMilestones.isNotEmpty, true);
      expect(BadgeDefinitions.allMilestones.isNotEmpty, true);
    });

    test('I badge Marathoner devono avere target incrementali', () {
      final milestones = BadgeDefinitions.marathonerMilestones;
      for (int i = 0; i < milestones.length - 1; i++) {
        expect(
          milestones[i + 1].targetHours,
          greaterThan(milestones[i].targetHours),
        );
      }
    });

    test('Verifica integrità ID e nextId', () {
      expect(
        BadgeDefinitions.marathonerMilestones[0].nextId,
        equals("mbronze"),
      );
      expect(BadgeDefinitions.marathonerMilestones[1].id, equals("mbronze"));

      expect(BadgeDefinitions.marathonerMilestones.last.nextId, isNull);
    });

    test('allMilestones deve contenere il numero corretto di badge totali', () {
      int totalCount =
          BadgeDefinitions.marathonerMilestones.length +
          BadgeDefinitions.obsessionMilestones.length +
          BadgeDefinitions.weekendMilestones.length +
          BadgeDefinitions.streakMilestones.length +
          BadgeDefinitions.completionistMilestones.length +
          BadgeDefinitions.nightOwlMilestones.length +
          BadgeDefinitions.genreMilestones.length;

      expect(BadgeDefinitions.allMilestones.length, equals(totalCount));
    });
  });
}
