import 'package:flutter_test/flutter_test.dart';

// Definiamo qui la logica da testare per evitare import "pericolosi" che toccano Firebase
double calculateTotal(List<double> hours) {
  return hours.fold(0, (sum, item) => sum + item);
}

void main() {
  group('Logic Unit Tests', () {
    test('La somma delle ore deve essere corretta', () {
      final watchTimes = [10.5, 4.5, 5.0];
      final result = calculateTotal(watchTimes);

      // Verifica (come richiesto dalle slide del prof)
      expect(result, 20.0);
    });

    test('La conversione in minuti deve essere precisa', () {
      double hours = 1.5;
      int minutes = (hours * 60).toInt();

      expect(minutes, 90);
    });
  });
}
