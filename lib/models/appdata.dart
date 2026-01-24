import 'series.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AppData {
  static List<Series> userSeries = [];
  static List<Map<String, String>> userBadges = [];
  
  static Future<void> initializeData() async {
    userSeries.clear();
    userBadges = [
      {"name": "Marathoner", "image": "assets/images/marathoner.png"},
      {"name": "Obsession", "image": "assets/images/obsession.png"},
      {"name": "Warrior", "image": "assets/images/warrior.png"},
      {"name": "Binge King", "image": "assets/images/marathoner.png"},
    ];

    final List<Map<String, dynamic>> localData = [
      {"name": "Peaky Blinders", "perc": 1.0, "time": 36, "ep": "Finished"},
      {"name": "Lost", "perc": 0.15, "time": 14, "ep": "S1 E5"},
      {"name": "Squid Game", "perc": 1.0, "time": 24, "ep": "Finished"},
      {"name": "Breaking Bad", "perc": 0.95, "time": 57, "ep": "S5 E12"},
      {"name": "Stranger Things", "perc": 0.88, "time": 42, "ep": "S4 E7"},
      {"name": "The Boys", "perc": 0.75, "time": 24, "ep": "S3 E4"},
      {"name": "Dark", "perc": 0.92, "time": 26, "ep": "S3 E6"},
      {"name": "The Crown", "perc": 0.40, "time": 50, "ep": "S4 E2"},
      {"name": "The Bear", "perc": 0.98, "time": 12, "ep": "S2 E10"},
      {"name": "Succession", "perc": 0.65, "time": 38, "ep": "S3 E5"},
      {"name": "Severance", "perc": 0.20, "time": 9, "ep": "S1 E2"},
      {"name": "The Last of Us", "perc": 0.94, "time": 10, "ep": "S1 E9"},
      {"name": "Better Call Saul", "perc": 0.80, "time": 60, "ep": "S6 E3"},
      {"name": "Friends", "perc": 1.0, "time": 85, "ep": "Finished"},
      {"name": "The Office", "perc": 0.55, "time": 72, "ep": "S6 E14"},
      {"name": "Black Mirror", "perc": 0.30, "time": 22, "ep": "S4 E1"},
      {"name": "Narcos", "perc": 0.85, "time": 25, "ep": "S3 E2"},
      {"name": "Wednesday", "perc": 0.90, "time": 8, "ep": "S1 E7"},
    {"name": "Money Heist", "perc": 0.99, "time": 46, "ep": "S5 E10"},
      {"name": "True Detective", "perc": 0.45, "time": 24, "ep": "S2 E1"},
      {"name": "Sherlock", "perc": 0.70, "time": 18, "ep": "S3 E2"},
      {"name": "Mindhunter", "perc": 0.50, "time": 19, "ep": "S2 E5"},
      {"name": "The Mandalorian", "perc": 0.60, "time": 16, "ep": "S2 E8"},
      {"name": "Vikings", "perc": 0.35, "time": 70, "ep": "S4 E12"},
      {"name": "Cobra Kai", "perc": 0.82, "time": 30, "ep": "S5 E1"},
      {"name": "Arcane", "perc": 0.96, "time": 6, "ep": "S1 E8"},
      {"name": "Ted Lasso", "perc": 0.10, "time": 22, "ep": "S1 E3"},
      {"name": "The Witcher", "perc": 0.25, "time": 24, "ep": "S2 E2"},
      {"name": "House of the Dragon", "perc": 0.89, "time": 10, "ep": "S1 E9"},
      {"name": "Euphoria", "perc": 0.48, "time": 16, "ep": "S2 E4"},
      {"name": "Fargo", "perc": 0.15, "time": 40, "ep": "S1 E6"},
    ];

  await Future.wait(localData.map((item) async {
      final url = await fetchImageUrl(item['name']);
      userSeries.add(Series(
        name: item['name'],
        imageUrl: url,
        percentage: item['perc'],
        totalHours: item['time'], 
        episode: item['ep'],
      ));
    }));
  }

  static Future<String> fetchImageUrl(String name) async {
    try {
      final res = await http.get(Uri.parse('https://api.tvmaze.com/singlesearch/shows?q=$name'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['image']?['medium'] ?? '';
      }
    } catch (e) { 
      debugPrint("Errore immagine per $name: $e"); 
    }
    return '';
  }
}