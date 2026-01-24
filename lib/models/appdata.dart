import 'series.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'userbadge.dart'; 

class AppData {
  static List<Series> userSeries = [];
  static List<UserBadge> userBadges = [];
  
  
  static Future<void> initializeData() async {
    userSeries.clear();
    
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

    int totalHoursSeen = 0;
    for (var series in userSeries) {
      totalHoursSeen += (series.totalHours * series.percentage).toInt();
    }

    userBadges = [];

    if (totalHoursSeen >= 24) {
      String mPath = "assets/images/marathoner_base.png";
      String mLabel = "1G";

      if (totalHoursSeen >= 2400) { 
        mPath = "assets/images/marathoner_diamond.png";
        mLabel = "100G";
      } else if (totalHoursSeen >= 480) { 
        mPath = "assets/images/marathoner_gold.png";
        mLabel = "20G";
      } else if (totalHoursSeen >= 240) {
        mPath = "assets/images/marathoner_silver.png";
        mLabel = "10G";
      } else if (totalHoursSeen >= 72) { 
        mPath = "assets/images/marathoner_bronze.png";
        mLabel = "3G";
      }

      userBadges.add(
        UserBadge(
          id: "marathoner",
          title: "Marathoner",
          imagePath: mPath,
          iconLabel: mLabel,
        ),
      );
    }
    /* LOGICA PURE OBSESSION (Temporaneamente statica)
       Quando avrai la logica temporale, userai una variabile tipo 'maxConsecutiveHours'
    */
    
    int maxConsecutiveHours = 3; // Questo valore verrà calcolato in futuro

    if (maxConsecutiveHours >= 1) {
      String pPath = "assets/images/pure_obsession_base.png";
      String pLabel = "1H";

      if (maxConsecutiveHours >= 20) {
        pPath = "assets/images/pure_obsession_diamond.png";
        pLabel = "20H";
      } else if (maxConsecutiveHours >= 14) {
        pPath = "assets/images/pure_obsession_gold.png";
        pLabel = "14H";
      } else if (maxConsecutiveHours >= 8) {
        pPath = "assets/images/pure_obsession_silver.png";
        pLabel = "8H";
      } else if (maxConsecutiveHours >= 3) {
        pPath = "assets/images/pure_obsession_bronze.png";
        pLabel = "3H";
      }

      userBadges.add(
        UserBadge(
          id: "pure_obsession",
          title: "Pure Obsession",
          imagePath: pPath,
          iconLabel: pLabel,
        ),
      );
    }

    /* LOGICA WEEKEND WARRIOR
       In futuro, questa variabile conterrà le ore viste tra Venerdì Sabato e Domenica
    */
    int weekendHours = 50; 

    if (weekendHours >= 3) {
      String wPath = "assets/images/weekend_warrior_base.png";
      String wLabel = "3H / 3G"; 

      if (weekendHours >= 48) {
        wPath = "assets/images/weekend_warrior_diamond.png";
        wLabel = "48H / 3G";
      } else if (weekendHours >= 24) {
        wPath = "assets/images/weekend_warrior_gold.png";
        wLabel = "24H / 3G";
      } else if (weekendHours >= 15) {
        wPath = "assets/images/weekend_warrior_silver.png";
        wLabel = "15H / 3G";
      } else if (weekendHours >= 10) {
        wPath = "assets/images/weekend_warrior_bronze.png";
        wLabel = "10H / 3G";
      }

      userBadges.add(
        UserBadge(
          id: "weekend_warrior",
          title: "Weekend Warrior",
          imagePath: wPath,
          iconLabel: wLabel,
        ),
      );
    }
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