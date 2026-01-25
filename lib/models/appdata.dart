import 'series.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'userbadge.dart'; 
import 'user.dart';
import 'package:flutter/material.dart';
class AppData {
  static List<Series> userSeries = [];
  static List<UserBadge> userBadges = [];
  static User? currentUser;
  static const Color primaryColor = Color(0xFF8C1C13);     // Bordeaux
  static const Color accentColor = Color(0xFF364156);      // Blu 
  static const Color backgroundColor = Color(0xFFEEF0E9);  // White like
  static const Color avatarColor = Color(0xFF4A5568);
  static const Color whiteColor = Colors.white;

  static final List<UserBadge> marathonerMilestones = [
  UserBadge(id: "mbase", title: "Marathoner", imagePath: "assets/images/marathoner_base.png", iconLabel: "1G", targetHours: 24, nextId: "mbronze"),
  UserBadge(id: "mbronze", title: "Marathoner", imagePath: "assets/images/marathoner_bronze.png", iconLabel: "3G", targetHours: 72, nextId: "msilver"),
  UserBadge(id: "msilver", title: "Marathoner", imagePath: "assets/images/marathoner_silver.png", iconLabel: "10G", targetHours: 240, nextId: "mgold"),
  UserBadge(id: "mgold", title: "Marathoner", imagePath: "assets/images/marathoner_gold.png", iconLabel: "20G", targetHours: 480, nextId: "mdiamond"),
  UserBadge(id: "mdiamond", title: "Marathoner", imagePath: "assets/images/marathoner_diamond.png", iconLabel: "100G", targetHours: 2400, nextId: null),
];
static final List<UserBadge> obsessionMilestones = [
  UserBadge(id: "pbase", title: "Pure Obsession", imagePath: "assets/images/pure_obsession_base.png", iconLabel: "1H", targetHours: 1, nextId: "pbronze"),
  UserBadge(id: "pbronze", title: "Pure Obsession", imagePath: "assets/images/pure_obsession_bronze.png", iconLabel: "3H", targetHours: 3, nextId: "psilver"),
  UserBadge(id: "psilver", title: "Pure Obsession", imagePath: "assets/images/pure_obsession_silver.png", iconLabel: "8H", targetHours: 8, nextId: "pgold"),
  UserBadge(id: "pgold", title: "Pure Obsession", imagePath: "assets/images/pure_obsession_gold.png", iconLabel: "14H", targetHours: 14, nextId: "pdiamond"),
  UserBadge(id: "pdiamond", title: "Pure Obsession", imagePath: "assets/images/pure_obsession_diamond.png", iconLabel: "20H", targetHours: 20, nextId: null),
];

static final List<UserBadge> weekendMilestones = [
  UserBadge(id: "wbase", title: "Weekend Warrior", imagePath: "assets/images/weekend_warrior_base.png", iconLabel: "3H", targetHours: 3, nextId: "wbronze"),
  UserBadge(id: "wbronze", title: "Weekend Warrior", imagePath: "assets/images/weekend_warrior_bronze.png", iconLabel: "10H", targetHours: 10, nextId: "wsilver"),
  UserBadge(id: "wsilver", title: "Weekend Warrior", imagePath: "assets/images/weekend_warrior_silver.png", iconLabel: "15H", targetHours: 15, nextId: "wgold"),
  UserBadge(id: "wgold", title: "Weekend Warrior", imagePath: "assets/images/weekend_warrior_gold.png", iconLabel: "24H", targetHours: 24, nextId: "wdiamond"),
  UserBadge(id: "wdiamond", title: "Weekend Warrior", imagePath: "assets/images/weekend_warrior_diamond.png", iconLabel: "48H", targetHours: 48, nextId: null),
];
//assign the badges to the user.
static void generateUserBadges() {
  userBadges.clear();
  if (currentUser == null) return;
  UserBadge? currentM; //nullable
  for (var badge in marathonerMilestones) {
    if (currentUser!.totalHoursWatched >= badge.targetHours) currentM = badge; //currentUser cannot be null
  }
  if (currentM != null) userBadges.add(currentM);
  UserBadge? currentO;
  for (var badge in obsessionMilestones) {
    if (currentUser!.maxConsecutiveHours >= badge.targetHours) currentO = badge;
  }
  if (currentO != null) userBadges.add(currentO);
  UserBadge? currentW;
  for (var badge in weekendMilestones) {
    if (currentUser!.weekendHours >= badge.targetHours) currentW = badge;
  }
  if (currentW != null) userBadges.add(currentW);
}

static UserBadge getMarathonerTarget() {
  double totalHours = getTotalWatchTimeHours();
  UserBadge target = marathonerMilestones.first; //considering 24h as the first target
  for (var badge in marathonerMilestones) {
    //if the target is reached, change the target to the next one
    if (totalHours >= badge.targetHours) {
      if (badge.nextId != null) {
        //take the first element of the list (.firstWhere) whith the corresponfing badge Id
        target = marathonerMilestones.firstWhere((b) => b.id == badge.nextId);
      } else {
        target = badge;
      }
    } else {
      target = badge;
      break;
    }
  }
  return target;
}
static UserBadge getObsessionTarget(int currentObsessionHours) {
  UserBadge target = obsessionMilestones.first;
  for (var badge in obsessionMilestones) {
    if (currentObsessionHours >= badge.targetHours) {
      if (badge.nextId != null) {
        //orElse: () => badge indicates to take the "badge" if badge.nextId doesn't exist
        target = obsessionMilestones.firstWhere((b) => b.id == badge.nextId, orElse: () => badge);
      } else {
        target = badge;
      }
    } else {
      target = badge;
      break;
    }
  }
  return target;
}

static UserBadge getWeekendTarget(int currentWeekendHours) {
  UserBadge target = weekendMilestones.first;
  for (var badge in weekendMilestones) {
    if (currentWeekendHours >= badge.targetHours) {
      if (badge.nextId != null) {
        target = weekendMilestones.firstWhere((b) => b.id == badge.nextId, orElse: () => badge);
      } else {
        target = badge;
      }
    } else {
      target = badge;
      break;
    }
  }
  return target;
}
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
  {"name": "The Office US", "perc": 0.55, "time": 72, "ep": "S6 E14"}, 
  {"name": "Black Mirror", "perc": 0.30, "time": 22, "ep": "S4 E1"},
  {"name": "Narcos", "perc": 0.85, "time": 25, "ep": "S3 E2"},
  {"name": "Wednesday", "perc": 0.90, "time": 8, "ep": "S1 E7"},
  {"name": "La Casa de Papel", "perc": 0.99, "time": 46, "ep": "S5 E10"}, 
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
// localData.map((item) to map the list in future Data
//await means that the application stop and wait for the information
int counter = 0;
    await Future.wait(localData.map((item) async {
      final myIndex = counter++;
      await Future.delayed(Duration(milliseconds: myIndex * 100)); //waiting delay for the image
      final url = await fetchImageUrl(item['name']);
      userSeries.add(Series(
        name: item['name'],
        imageUrl: url,
        percentage: item['perc'],
        totalHours: item['time'], 
        episode: item['ep'],
      ));
    }));

    
    userBadges = [];
  double totalHours = getTotalWatchTimeHours();


currentUser = User(
    name: "Francesco\n Lo Monaco", 
    totalHoursWatched: totalHours,   
    maxConsecutiveHours: 3,     
    weekendHours: 40,  
    notification: true,        
  );
  generateUserBadges();
  }
static Future<String> fetchImageUrl(String name) async {
  //first try the singlesearch, if no image was found, try to scan the complete list of names
  try {
    final singleRes = await http.get(Uri.parse('https://api.tvmaze.com/singlesearch/shows?q=$name'));
    if (singleRes.statusCode == 200) {
      final data = json.decode(singleRes.body);
      if (data['image'] != null && data['image']['medium'] != null) {
        return data['image']['medium'];
      }
    }
    final searchRes = await http.get(Uri.parse('https://api.tvmaze.com/search/shows?q=$name'));
    if (searchRes.statusCode == 200) {
      final List data = json.decode(searchRes.body);
      for (var result in data) {
        final show = result['show'];
        if (show['image'] != null && show['image']['medium'] != null) {
          return show['image']['medium'];
        }
      }
    }
  } catch (e) {
    debugPrint("Errore immagine per $name: $e");
  }
  return ''; 
}

static double getTotalWatchTimeHours() {
  if (userSeries.isEmpty) return 0.0; 
  double total = 0;
  for (var series in userSeries) {
    total += (series.totalHours * series.percentage);
  }
  return total;
}

static Map<String, int> getTotalWatchTimeSplit() {
  double totalHours = getTotalWatchTimeHours();
  return {
    "days": (totalHours / 24).floor(),
    "hours": (totalHours % 24).floor(),
    "minutes": ((totalHours - totalHours.floor()) * 60).round(),
  };
}
}