import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/user_badge.dart';

void main() {
  group('UserBadge Model Tests', () {
    test('Il modello UserBadge deve memorizzare correttamente i parametri', () {
      final badge = UserBadge(
        id: "test_id",
        title: "Test Badge",
        imagePath: "assets/test.png",
        iconLabel: "5h",
        targetHours: 5.0,
        nextId: "next_test_id",
      );

      expect(badge.id, "test_id");
      expect(badge.title, "Test Badge");
      expect(badge.imagePath, "assets/test.png");
      expect(badge.iconLabel, "5h");
      expect(badge.targetHours, 5.0);
      expect(badge.nextId, "next_test_id");
    });

    test('Il campo nextId può essere nullo', () {
      final badge = UserBadge(
        id: "last_badge",
        title: "Final Boss",
        imagePath: "assets/final.png",
        iconLabel: "100h",
        targetHours: 100.0,
        nextId: null, // Caso del badge finale
      );

      expect(badge.nextId, isNull);
    });
  });
}
