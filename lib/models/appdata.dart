import 'series.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'userbadge.dart'; 
import 'user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
class AppData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance; 
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
static void generateUserBadges() {
  userBadges.clear();
  if (currentUser == null) return;
  UserBadge? currentM; 
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
static UserBadge getObsessionTarget(double currentObsessionHours) {
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

static UserBadge getWeekendTarget(double currentWeekendHours) {
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
 /* static Future<void> initializeData() async {
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
  }*/

  //doc.id returns the name of the document
  //doc.data() returns a map Map<String, dynamic> with all the data in the document
  //doc.reference is the path of the document

  static Future<void> initializeData() async {
    userSeries.clear();

    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final userDoc = _db.collection('users').doc(firebaseUser.uid);
    final snapshot = await userDoc.get(); //get() returns a future which contain a snapshot of the data in the Doc

    if (!snapshot.exists) {
      // if there's no data in the DB, let's populate
      await _populateFirstTime(firebaseUser, userDoc);
    } else {
      final data = snapshot.data()!; 
      currentUser = User(
        name: data['name'] ?? firebaseUser.displayName ?? "User", //firebaseUser.displayName contains the google user name
        totalHoursWatched: (data['totalHoursWatched'] ?? 0).toDouble(),
        maxConsecutiveHours: data['maxConsecutiveHours'] ?? 0,
        weekendHours:( data['weekendHours'] ?? 0).toDouble(),
        notification: data['notification'] ?? true,
        photoUrl: firebaseUser.photoURL,
      );

final seriesSnap = await userDoc.collection('series').get();
for (var doc in seriesSnap.docs) { //.docs transforms the result in a List
  double realHours = await calculateSeriesTotalHours(doc.id);
  
  userSeries.add(Series(
    name: doc.id,
    imageUrl: doc['imageUrl'],
    percentage: (doc['percentage'] ?? 0).toDouble(),
    totalHours: realHours, 
    episode: doc['episode'] ?? "",
  ));
}
    }
    generateUserBadges();
  }

static Stream<DocumentSnapshot> userStream() {
  final firebaseUser = auth.FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) return const Stream.empty();
  
  return _db.collection('users').doc(firebaseUser.uid).snapshots();
  // differently from get(), the snapshot keep the data updated
}

static Stream<QuerySnapshot> seriesStream() {
  final firebaseUser = auth.FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) return const Stream.empty();
  
  return _db.collection('users').doc(firebaseUser.uid).collection('series').snapshots();
}

static Future<void> _populateFirstTime(auth.User fbUser, DocumentReference docRef) async {
  await docRef.set({
    'name': fbUser.displayName ?? "User",
    'totalHoursWatched': 0.0,
    'maxConsecutiveHours': 0.0,
    'weekendHours': 0.0,
    'notification': true,
  }, SetOptions(merge: true));

  final List<String> seriesToTrack = ["Peaky Blinders", "Breaking Bad", "The Bear"];

  DateTime venerdi = DateTime(2025, 10, 24, 20, 0); 
  DateTime sabato = DateTime(2025, 10, 25, 14, 0);  
  DateTime lunedi = DateTime(2025, 10, 27, 09, 0);  

  for (String name in seriesToTrack) {
    final response = await http.get(Uri.parse('https://api.tvmaze.com/singlesearch/shows?q=$name&embed=episodes'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List episodesFromApi = data['_embedded']['episodes'];
      final String imageUrl = data['image']?['medium'] ?? "";

      DocumentReference seriesRef = docRef.collection('series').doc(name); // take the serie with name "name"

      await seriesRef.set({
        'imageUrl': imageUrl,
        'percentage': 0.0,
        'totalHours': 0.0,
        'episode': "S1 E1",
      }, SetOptions(merge: true));

      for (var ep in episodesFromApi) {
        int seasonNum = ep['season'];
        int episodeNum = ep['number'];
        int runtime = ep['runtime'] ?? 60;
        
        bool isWatched = false;
        DateTime? watchDate;

        if (name == "Breaking Bad" && seasonNum == 1) {
          isWatched = episodeNum <= 3;
          watchDate = lunedi.add(Duration(minutes: (episodeNum - 1) * 50));
        } 
        else if (name == "Peaky Blinders" && seasonNum == 1) {
          isWatched = episodeNum <= 4;
          if (episodeNum <= 2) {
            watchDate = venerdi.add(Duration(minutes: (episodeNum - 1) * 65));
          } else {
            watchDate = sabato.add(Duration(minutes: (episodeNum - 3) * 65));
          }
        }
        else if (name == "The Bear") {
          isWatched = (seasonNum == 1 && episodeNum == 1);
          watchDate = DateTime.now().subtract(const Duration(days: 5));
        }

        DocumentReference seasonRef = seriesRef.collection('seasons').doc('Season $seasonNum'); // take the season number seasonNum
        await seasonRef.set({'season_number': seasonNum}, SetOptions(merge: true));

        await seasonRef.collection('episodes').doc('Episode $episodeNum').set({
          'episode_number': episodeNum,
          'runtime': runtime,
          'timestamp': watchDate != null ? Timestamp.fromDate(watchDate) : FieldValue.serverTimestamp(),
          'watched': isWatched,
        }, SetOptions(merge: true));
      }

      await syncSeriesTotalHours(name);
    }
  }
}

static Future<void> setupNewTechnicalStructure() async {
  final user = auth.FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  List<String> seriesToUpdate = ["Peaky Blinders", "Lost", "Breaking Bad"];

  for (String seriesName in seriesToUpdate) {
    DocumentReference seriesRef = userDoc.collection('series').doc(seriesName);

    DocumentReference seasonRef = seriesRef.collection('seasons').doc('Season 1');
    await seasonRef.set({'season_number': 1});

    await seasonRef.collection('episodes').doc('Episode 1').set({
      'episode_number': 1,
      'runtime': 45,
      'timestamp': DateTime.now(),
      'watched': true,
    });
      }
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
    debugPrint("Image error for $name: $e");
  }
  return ''; 
}

static double getTotalWatchTimeHours() {
  if (userSeries.isEmpty) return 0.0; 
  double total = 0;
  for (var series in userSeries) {
    total += (series.totalHours);
  }
  final firebaseUser = auth.FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    _db.collection('users').doc(firebaseUser.uid).update({
      'totalHoursWatched': total,
    });
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

static Future<double> calculateSeriesTotalHours(String seriesName) async {
  final user = auth.FirebaseAuth.instance.currentUser;
  if (user == null) return 0.0;

  double totalMinutes = 0;

  final seasonsSnapshot = await _db
      .collection('users')
      .doc(user.uid)
      .collection('series')
      .doc(seriesName)
      .collection('seasons')
      .get();

  for (var seasonDoc in seasonsSnapshot.docs) {
    final episodesSnapshot = await seasonDoc.reference
        .collection('episodes')
        .where('watched', isEqualTo: true)
        .get();
    for (var episodeDoc in episodesSnapshot.docs) {
      totalMinutes += (episodeDoc.data()['runtime'] ?? 0);
    }
  }

  return totalMinutes / 60.0;
}
static Future<List<dynamic>> fetchSeriesEpisodes(String seriesName) async {
  try {
    final res = await http.get(Uri.parse('https://api.tvmaze.com/singlesearch/shows?q=$seriesName&embed=episodes'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['_embedded']['episodes'] as List<dynamic>;
    }
  } catch (e) {
    debugPrint("fetch episode error: $e");
  }
  return [];
}
static Future<void> syncSeriesTotalHours(String seriesName) async {
  final user = auth.FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final seriesRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('series')
      .doc(seriesName);

  double watchedMinutes = 0;

  final seasonsSnap = await seriesRef.collection('seasons').get();
  for (var seasonDoc in seasonsSnap.docs) {
    final episodesSnap = await seasonDoc.reference
        .collection('episodes')
        .where('watched', isEqualTo: true)
        .get();

    for (var epDoc in episodesSnap.docs) {
      watchedMinutes += (epDoc.data()['runtime'] ?? 0);
    }
  }

  double watchedHours = watchedMinutes / 60.0;

  double totalSeriesHours = await getSeriesTotalRuntimeFromApi(seriesName);

  double newPercentage = watchedHours / totalSeriesHours;
  if (newPercentage > 1.0) newPercentage = 1.0; 

  await seriesRef.update({
    'totalHours': watchedHours,
    'percentage': newPercentage,
  });
  await calculatePureObsession(seriesName);
  await calculateWeekendWarrior();
}
static Future<double> getSeriesTotalRuntimeFromApi(String seriesName) async {
  try {
    final response = await http.get(Uri.parse(
        'https://api.tvmaze.com/singlesearch/shows?q=$seriesName&embed=episodes'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List episodes = data['_embedded']['episodes'];
      
      int totalMinutes = 0;
      for (var ep in episodes) {
        totalMinutes += (ep['runtime'] as int? ?? 0);
      }
      return totalMinutes / 60.0; 
    }
  } catch (e) {
    debugPrint("Errore recupero ore totali API: $e");
  }
  return 1.0; 
}

static Future<void> calculatePureObsession(String seriesName) async {
  final user = auth.FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final seriesRef = _db.collection('users').doc(user.uid).collection('series').doc(seriesName);
  
  List<Map<String, dynamic>> watchedEpisodes = [];
  final seasonsSnap = await seriesRef.collection('seasons').get();
  
  for (var season in seasonsSnap.docs) {
    final epSnap = await season.reference.collection('episodes')
        .where('watched', isEqualTo: true)
        .get();
    for (var doc in epSnap.docs) {
      watchedEpisodes.add(doc.data());
    }
  }

  if (watchedEpisodes.isEmpty) return;

  watchedEpisodes.sort((a, b) {
    final tA = a['timestamp'] as Timestamp?;
    final tB = b['timestamp'] as Timestamp?;
    if (tA == null || tB == null) return 0;
    return tA.compareTo(tB);
  });

  double maxSessionHours = 0;
  double currentSessionMinutes = 0;
  
  for (int i = 0; i < watchedEpisodes.length; i++) {
    double runtime = (watchedEpisodes[i]['runtime'] ?? 0).toDouble();
    
    if (i == 0) {
      currentSessionMinutes = runtime;
    } else {
      final currentTimestamp = watchedEpisodes[i]['timestamp'] as Timestamp?;
      final previousTimestamp = watchedEpisodes[i-1]['timestamp'] as Timestamp?;
      
      if (currentTimestamp != null && previousTimestamp != null) {
        DateTime currentTime = currentTimestamp.toDate();
        DateTime previousTime = previousTimestamp.toDate();
        double previousRuntime = (watchedEpisodes[i-1]['runtime'] ?? 0).toDouble();

        int diffInMinutes = currentTime.difference(previousTime).inMinutes;
        
        if (diffInMinutes <= (previousRuntime + 10)) {
          currentSessionMinutes += runtime;
        } else {
          if ((currentSessionMinutes / 60) > maxSessionHours) {
            maxSessionHours = currentSessionMinutes / 60;
          }
          currentSessionMinutes = runtime; 
        }
      }
    }
  }
  
  if ((currentSessionMinutes / 60) > maxSessionHours) {
    maxSessionHours = currentSessionMinutes / 60;
  }

  final userDoc = _db.collection('users').doc(user.uid);
  final userSnap = await userDoc.get();
  double recordAttuale = (userSnap.data()?['maxConsecutiveHours'] ?? 0).toDouble();

  if (maxSessionHours > recordAttuale) {
    await userDoc.update({'maxConsecutiveHours': maxSessionHours});
  }
}
static Future<void> calculateWeekendWarrior() async {
  final user = auth.FirebaseAuth.instance.currentUser;
  if (user == null) return;

  
  Map<String, double> weekendGroups = {};

  final seriesSnap = await _db.collection('users').doc(user.uid).collection('series').get();

  for (var seriesDoc in seriesSnap.docs) {
    final seasonsSnap = await seriesDoc.reference.collection('seasons').get();
    for (var seasonDoc in seasonsSnap.docs) {
      final episodesSnap = await seasonDoc.reference.collection('episodes')
          .where('watched', isEqualTo: true)
          .get();

      for (var epDoc in episodesSnap.docs) {
        final data = epDoc.data();
        if (data['timestamp'] != null) {
          DateTime date = (data['timestamp'] as Timestamp).toDate();
          
          if (date.weekday >= DateTime.friday && date.weekday <= DateTime.sunday) {
          
            String weekendKey = "${date.year}-${_getIsoWeekNumber(date)}";
            
            double runtime = (data['runtime'] ?? 0).toDouble();
            weekendGroups[weekendKey] = (weekendGroups[weekendKey] ?? 0) + runtime;
          }
        }
      }
    }
  }

  double maxWeekendMinutes = 0;
  if (weekendGroups.isNotEmpty) {
    maxWeekendMinutes = weekendGroups.values.reduce((a, b) => a > b ? a : b);
  }

  double maxWeekendHours = maxWeekendMinutes / 60.0;

  await _db.collection('users').doc(user.uid).set({
    'weekendHours': maxWeekendHours,
  }, SetOptions(merge: true));
  
}

static int _getIsoWeekNumber(DateTime date) {
  int daysSinceJan1 = date.difference(DateTime(date.year, 1, 1)).inDays;
  return ((daysSinceJan1 + DateTime(date.year, 1, 1).weekday - 1) / 7).floor() + 1;
}


}