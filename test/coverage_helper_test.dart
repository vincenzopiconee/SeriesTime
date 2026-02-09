// ignore_for_file: unused_import
import 'package:flutter_test/flutter_test.dart';

// IMPORTA QUI TUTTI I TUOI FILE .DART DELLA CARTELLA LIB
import 'package:seriestime/main.dart';
import 'package:seriestime/services/stats_logic.dart';
import 'package:seriestime/services/series_logic.dart';
import 'package:seriestime/services/tmdb_service.dart';
import 'package:seriestime/screens/settings_screen.dart';
import 'package:seriestime/screens/profile_screen.dart';
import 'package:seriestime/widgets/auth_gate.dart';
import 'package:seriestime/widgets/notification_banner.dart';
import 'package:seriestime/widgets/season_tile.dart';
// Aggiungi qui ogni altro file .dart che hai in lib o nelle sottocartelle

void main() {
  test('Mark files for coverage', () {
    expect(true, isTrue);
  });
}
