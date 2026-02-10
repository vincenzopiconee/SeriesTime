import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/data/app_data.dart';

void main() {
  test('Verifica colori e costanti AppData per coverage', () {
    expect(AppData.primaryColor, isNotNull);
    expect(AppData.tmdbApiKey, isNotEmpty);
  });

  test('Verifica calcolo split tempo da AppData', () {
    AppData.userSeries = [];

    final split = AppData.getTotalWatchTimeSplit();
    expect(split["days"], 0);
    expect(split["hours"], 0);
  });
}
