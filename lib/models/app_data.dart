import 'next_episode_info.dart';
import 'series.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_badge.dart';
import 'user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

enum ChartPeriod { year, month, week }

class AppData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String tmdbApiKey = "1a4c56551c8917b157c4a6fdd2fca54d";
  static List<Series> userSeries = [];
  static List<UserBadge> userBadges = [];
  static User? currentUser;
  static const Color primaryColor = Color(0xFF791209);
  static const Color accentColor = Color(0xFF364156); 
  static const Color backgroundColor = Color(0xFFEEF0E9);
  static const Color avatarColor = Color(0xFF4A5568);
  static const Color whiteColor = Colors.white;

  static final List<UserBadge> marathonerMilestones = [
    UserBadge(
      id: "mbase",
      title: "Marathoner",
      imagePath: "assets/images/marathoner_base.png",
      iconLabel: "1d",
      targetHours: 24,
      nextId: "mbronze",
    ),
    UserBadge(
      id: "mbronze",
      title: "Marathoner",
      imagePath: "assets/images/marathoner_bronze.png",
      iconLabel: "3d",
      targetHours: 72,
      nextId: "msilver",
    ),
    UserBadge(
      id: "msilver",
      title: "Marathoner",
      imagePath: "assets/images/marathoner_silver.png",
      iconLabel: "10d",
      targetHours: 240,
      nextId: "mgold",
    ),
    UserBadge(
      id: "mgold",
      title: "Marathoner",
      imagePath: "assets/images/marathoner_gold.png",
      iconLabel: "20d",
      targetHours: 480,
      nextId: "mdiamond",
    ),
    UserBadge(
      id: "mdiamond",
      title: "Marathoner",
      imagePath: "assets/images/marathoner_diamond.png",
      iconLabel: "100d",
      targetHours: 2400,
      nextId: null,
    ),
  ];

  static final List<UserBadge> obsessionMilestones = [
    UserBadge(
      id: "pbase",
      title: "Pure Obsession",
      imagePath: "assets/images/pure_obsession_base.png",
      iconLabel: "1h",
      targetHours: 1,
      nextId: "pbronze",
    ),
    UserBadge(
      id: "pbronze",
      title: "Pure Obsession",
      imagePath: "assets/images/pure_obsession_bronze.png",
      iconLabel: "3h",
      targetHours: 3,
      nextId: "psilver",
    ),
    UserBadge(
      id: "psilver",
      title: "Pure Obsession",
      imagePath: "assets/images/pure_obsession_silver.png",
      iconLabel: "8h",
      targetHours: 8,
      nextId: "pgold",
    ),
    UserBadge(
      id: "pgold",
      title: "Pure Obsession",
      imagePath: "assets/images/pure_obsession_gold.png",
      iconLabel: "14h",
      targetHours: 14,
      nextId: "pdiamond",
    ),
    UserBadge(
      id: "pdiamond",
      title: "Pure Obsession",
      imagePath: "assets/images/pure_obsession_diamond.png",
      iconLabel: "20h",
      targetHours: 20,
      nextId: null,
    ),
  ];

  static final List<UserBadge> weekendMilestones = [
    UserBadge(
      id: "wbase",
      title: "Weekend Warrior",
      imagePath: "assets/images/weekend_warrior_base.png",
      iconLabel: "3h",
      targetHours: 3,
      nextId: "wbronze",
    ),
    UserBadge(
      id: "wbronze",
      title: "Weekend Warrior",
      imagePath: "assets/images/weekend_warrior_bronze.png",
      iconLabel: "10h",
      targetHours: 10,
      nextId: "wsilver",
    ),
    UserBadge(
      id: "wsilver",
      title: "Weekend Warrior",
      imagePath: "assets/images/weekend_warrior_silver.png",
      iconLabel: "15h",
      targetHours: 15,
      nextId: "wgold",
    ),
    UserBadge(
      id: "wgold",
      title: "Weekend Warrior",
      imagePath: "assets/images/weekend_warrior_gold.png",
      iconLabel: "24h",
      targetHours: 24,
      nextId: "wdiamond",
    ),
    UserBadge(
      id: "wdiamond",
      title: "Weekend Warrior",
      imagePath: "assets/images/weekend_warrior_diamond.png",
      iconLabel: "48h",
      targetHours: 48,
      nextId: null,
    ),
  ];

  static final List<UserBadge> streakMilestones = [
    UserBadge(
      id: "sbase",
      title: "Streak",
      imagePath: "assets/images/streak_base.png",
      iconLabel: "7d",
      targetHours: 7,
      nextId: "sbronze",
    ),
    UserBadge(
      id: "sbronze",
      title: "Streak",
      imagePath: "assets/images/streak_bronze.png",
      iconLabel: "10d",
      targetHours: 10,
      nextId: "ssilver",
    ),
    UserBadge(
      id: "ssilver",
      title: "Streak",
      imagePath: "assets/images/streak_silver.png",
      iconLabel: "20d",
      targetHours: 20,
      nextId: "sgold",
    ),
    UserBadge(
      id: "sgold",
      title: "Streak",
      imagePath: "assets/images/streak_gold.png",
      iconLabel: "50d",
      targetHours: 50,
      nextId: "sdiamond",
    ),
    UserBadge(
      id: "sdiamond",
      title: "Streak",
      imagePath: "assets/images/streak_diamond.png",
      iconLabel: "100d",
      targetHours: 100,
      nextId: null,
    ),
  ];

  static final List<UserBadge> completionistMilestones = [
    UserBadge(
      id: "tpbase",
      title: "The Perfectionist",
      imagePath: "assets/images/the_completionist_base.png",
      iconLabel: "1 Series",
      targetHours: 1,
      nextId: "tpbronze",
    ),
    UserBadge(
      id: "tpbronze",
      title: "The Perfectionist",
      imagePath: "assets/images/the_completionist_bronze.png",
      iconLabel: "3 Series",
      targetHours: 3,
      nextId: "tpsilver",
    ),
    UserBadge(
      id: "tpsilver",
      title: "The Perfectionist",
      imagePath: "assets/images/the_completionist_silver.png",
      iconLabel: "10 Series",
      targetHours: 10,
      nextId: "tpgold",
    ),
    UserBadge(
      id: "tpgold",
      title: "The Perfectionist",
      imagePath: "assets/images/the_completionist_gold.png",
      iconLabel: "20 Series",
      targetHours: 20,
      nextId: "tpdiamond",
    ),
    UserBadge(
      id: "tpdiamond",
      title: "The Perfectionist",
      imagePath: "assets/images/the_completionist_diamond.png",
      iconLabel: "50 Series",
      targetHours: 50,
      nextId: null,
    ),
  ];
  static final List<UserBadge> nightOwlMilestones = [
    UserBadge(
      id: "nobase",
      title: "The Night Owl",
      imagePath: "assets/images/the_night_owl_base.png",
      iconLabel: "1h",
      targetHours: 1,
      nextId: "nobronze",
    ),
    UserBadge(
      id: "nobronze",
      title: "The Night Owl",
      imagePath: "assets/images/the_night_owl_bronze.png",
      iconLabel: "5h",
      targetHours: 5,
      nextId: "nosilver",
    ),
    UserBadge(
      id: "nosilver",
      title: "The Night Owl",
      imagePath: "assets/images/the_night_owl_silver.png",
      iconLabel: "15h",
      targetHours: 15,
      nextId: "nogold",
    ),
    UserBadge(
      id: "nogold",
      title: "The Night Owl",
      imagePath: "assets/images/the_night_owl_gold.png",
      iconLabel: "30h",
      targetHours: 30,
      nextId: "nodiamond",
    ),
    UserBadge(
      id: "nodiamond",
      title: "The Night Owl",
      imagePath: "assets/images/the_night_owl_diamond.png",
      iconLabel: "50h",
      targetHours: 50,
      nextId: null,
    ),
  ];
  static final List<UserBadge> genreMilestones = [
    UserBadge(
      id: "gbase",
      title: "Genre Explorer",
      imagePath: "assets/images/genre_explorer_base.png",
      iconLabel: "1 Genres",
      targetHours: 1,
      nextId: "gbronze",
    ),
    UserBadge(
      id: "gbronze",
      title: "Genre Explorer",
      imagePath: "assets/images/genre_explorer_bronze.png",
      iconLabel: "3 Genres",
      targetHours: 3,
      nextId: "gsilver",
    ),
    UserBadge(
      id: "gsilver",
      title: "Genre Explorer",
      imagePath: "assets/images/genre_explorer_silver.png",
      iconLabel: "4 Genres",
      targetHours: 4,
      nextId: "ggold",
    ),
    UserBadge(
      id: "ggold",
      title: "Genre Explorer",
      imagePath: "assets/images/genre_explorer_gold.png",
      iconLabel: "6 Genres",
      targetHours: 6,
      nextId: "gdiamond",
    ),
    UserBadge(
      id: "gdiamond",
      title: "Genre Explorer",
      imagePath: "assets/images/genre_explorer_diamond.png",
      iconLabel: "8 Genres",
      targetHours: 8,
      nextId: null,
    ),
  ];

  static void resetData() {
    userSeries.clear();
    userBadges.clear();
    currentUser = null;
  }

  static void generateUserBadges() {
    userBadges.clear();
    if (currentUser == null) return;
    UserBadge? currentM;
    for (var badge in marathonerMilestones) {
      if (currentUser!.totalHoursWatched >= badge.targetHours) {
        currentM = badge; 
      }
    }
    if (currentM != null) userBadges.add(currentM);
    UserBadge? currentO;
    for (var badge in obsessionMilestones) {
      if (currentUser!.maxConsecutiveHours >= badge.targetHours) {
        currentO = badge;
      }
    }
    if (currentO != null) userBadges.add(currentO);
    UserBadge? currentW;
    for (var badge in weekendMilestones) {
      if (currentUser!.weekendHours >= badge.targetHours) currentW = badge;
    }
    if (currentW != null) userBadges.add(currentW);

    UserBadge? currentS;
    for (var badge in streakMilestones) {
      if (currentUser!.seriesStreak >= badge.targetHours) currentS = badge;
    }
    if (currentS != null) userBadges.add(currentS);

    UserBadge? currentC;
    int completedCount = userSeries.where((s) => s.percentage >= 1.0).length;
    for (var badge in completionistMilestones) {
      if (completedCount >= badge.targetHours) currentC = badge;
    }
    if (currentC != null) userBadges.add(currentC);
    UserBadge? currentNO;

    for (var badge in nightOwlMilestones) {
      if (currentUser!.nightOwlHours >= badge.targetHours) currentNO = badge;
    }
    if (currentNO != null) userBadges.add(currentNO);

    UserBadge? currentG;
    for (var badge in genreMilestones) {
      if (currentUser!.uniqueGenresCount >= badge.targetHours) currentG = badge;
    }
    if (currentG != null) userBadges.add(currentG);
  }

  static UserBadge getMarathonerTarget() {
    double totalHours = getTotalWatchTimeHours();
    UserBadge target =
        marathonerMilestones.first; 
    for (var badge in marathonerMilestones) {
      if (totalHours >= badge.targetHours) {
        if (badge.nextId != null) {
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
          target = obsessionMilestones.firstWhere(
            (b) => b.id == badge.nextId,
            orElse: () => badge,
          );
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
          target = weekendMilestones.firstWhere(
            (b) => b.id == badge.nextId,
            orElse: () => badge,
          );
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

  static UserBadge getGenreTarget(int currentCount) {
    UserBadge target = genreMilestones.first;
    for (var badge in genreMilestones) {
      if (currentCount >= badge.targetHours) {
        if (badge.nextId != null) {
          target = genreMilestones.firstWhere(
            (b) => b.id == badge.nextId,
            orElse: () => badge,
          );
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
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final userDoc = _db.collection('users').doc(firebaseUser.uid);
    var snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await _populateFirstTime(firebaseUser, userDoc);
      snapshot = await userDoc.get(); 
    }

    final data = snapshot.data()!;

    String? originalPhotoUrl = data['photoUrl'] ?? firebaseUser.photoURL;
    String? highResPhotoUrl = originalPhotoUrl;

    if (originalPhotoUrl != null && originalPhotoUrl.contains('googleusercontent.com')) {
      highResPhotoUrl = originalPhotoUrl.replaceFirst('s96-c', 's400-c');
    }

    currentUser = User(
      name: data['name'] ?? firebaseUser.displayName ?? "User",
      totalHoursWatched: (data['totalHoursWatched'] ?? 0).toDouble(),
      maxConsecutiveHours: (data['maxConsecutiveHours'] ?? 0).toDouble(),
      weekendHours: (data['weekendHours'] ?? 0).toDouble(),
      nightOwlHours: (data['nightOwlHours'] ?? 0).toDouble(),
      uniqueGenresCount: (data['uniqueGenresCount'] ?? 0).toInt(),
      claimedBadgeIds: List<String>.from(data['claimedBadgeIds'] ?? []),
      photoUrl: highResPhotoUrl,
      seriesStreak: data['seriesStreak'] ?? 0,
      lastViewDate: (data['lastViewDate'] as Timestamp?)?.toDate(),
    );

    final seriesSnap = await userDoc.collection('series').get();
    for (var doc in seriesSnap.docs) {
      final sData = doc.data();
      userSeries.add(
        Series(
          id: sData['id'] ?? 0,
          name: doc.id,
          imageUrl: sData['imageUrl'],
          percentage: (sData['percentage'] ?? 0).toDouble(),
          totalHours: (sData['totalHours'] ?? 0).toDouble(),
          episode: sData['episode'] ?? "",
          lastEpisodeTitle: sData['lastEpisodeTitle'] ?? "",
          nextEpisodeAirDate: sData['nextEpisodeAirDate'],
          seriesDuration: (sData['seriesDuration'] ?? 0).toDouble(),
          isFavorite: sData['isFavorite'] ?? false,
          completed: sData['completed'] ?? false,
        ),
      );
    }
    
    generateUserBadges();
  }

  static Stream<DocumentSnapshot> userStream() {
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return const Stream.empty();

    return _db.collection('users').doc(firebaseUser.uid).snapshots();
  }

  static Stream<QuerySnapshot> seriesStream() {
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(firebaseUser.uid)
        .collection('series')
        .snapshots();
  }

  static Future<void> _populateFirstTime(
    auth.User fbUser,
    DocumentReference docRef,
  ) async {
    await docRef.set({
      'name': fbUser.displayName ?? "User",
      'totalHoursWatched': 0.0,
      'maxConsecutiveHours': 0.0,
      'weekendHours': 0.0,
      'nightOwlHours': 0.0,
    }, SetOptions(merge: true));
  }

  static Future<String> fetchImageUrl(String name) async {
    final String url =
        "https://api.themoviedb.org/3/search/tv?api_key=$tmdbApiKey&query=${Uri.encodeComponent(name)}&language=it-IT";

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SeriesTimeApp/1.0',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          String path = data['results'][0]['poster_path'] ?? "";
          return "https://image.tmdb.org/t/p/w500$path";
        }
      }
    } catch (e) {
      debugPrint("Errore immagine TMDB per $name: $e");
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

  static UserBadge? getFirstUnclaimedBadge() {
    final all = getAllUnclaimedBadges();
    return all.isNotEmpty ? all.first : null;
  }

  static List<UserBadge> getAllUnclaimedBadges() {
    if (currentUser == null) return [];

    final allMilestones = [
      ...marathonerMilestones,
      ...obsessionMilestones,
      ...weekendMilestones,
      ...streakMilestones,
      ...completionistMilestones,
      ...nightOwlMilestones,
      ...genreMilestones,
    ];

    final stats = {
      "Marathoner": currentUser!.totalHoursWatched,
      "Pure Obsession": currentUser!.maxConsecutiveHours,
      "Weekend Warrior": currentUser!.weekendHours,
      "Streak": currentUser!.seriesStreak.toDouble(),
      "The Perfectionist": userSeries
          .where((s) => s.percentage >= 1.0)
          .length
          .toDouble(),
      "The Night Owl": currentUser!.nightOwlHours,
      "Genre Explorer": currentUser!.uniqueGenresCount.toDouble(),
    };

    List<UserBadge> unlocked = [];

    for (var badge in allMilestones) {
      double currentVal = stats[badge.title] ?? 0.0;
      if (currentVal > 0.0 &&
          currentVal >= badge.targetHours &&
          !currentUser!.claimedBadgeIds.contains(badge.id)) {
        unlocked.add(badge);
      }
    }
    return unlocked;
  }

  static Future<void> syncSeriesTotalHours(String seriesName) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final seriesRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('series')
        .doc(seriesName);

    double watchedMinutes = 0;
    int maxSeason = -1;
    int maxEpisode = -1;
    String displayLabel = "S1 E1";
    String displayTitle = "";
    String? displayAirDate;
    bool isSeriesCompleted = false;

    final seriesDoc = await seriesRef.get();
    int seriesId = 0;
    if (seriesDoc.exists) {
      seriesId = seriesDoc.data()?['id'] ?? 0;
    }

    final seasonsSnap = await seriesRef.collection('seasons').get();

    for (var seasonDoc in seasonsSnap.docs) {
      final episodesSnap = await seasonDoc.reference
          .collection('episodes')
          .where('watched', isEqualTo: true)
          .get();

      for (var epDoc in episodesSnap.docs) {
        final data = epDoc.data();
        watchedMinutes += (data['runtime'] ?? 0);

        int sNum =
            data['season_number'] ??
            int.tryParse(seasonDoc.id.split(' ').last) ??
            0;
        int eNum = data['episode_number'] ?? 0;

        if (sNum > maxSeason) {
          maxSeason = sNum;
          maxEpisode = eNum;
        } else if (sNum == maxSeason && eNum > maxEpisode) {
          maxEpisode = eNum;
        }
      }
    }

    if (seriesId != 0) {
      try {
        int targetSeason = maxSeason < 1 ? 1 : maxSeason;
        int lastWatchedEpInSeason = maxEpisode < 1 ? 0 : maxEpisode;

        final urlSeason =
            "https://api.themoviedb.org/3/tv/$seriesId/season/$targetSeason?api_key=$tmdbApiKey&language=en-US";
        final resSeason = await http.get(Uri.parse(urlSeason));

        if (resSeason.statusCode == 200) {
          final sData = json.decode(resSeason.body);
          final List episodes = sData['episodes'] ?? [];

          var nextEp = episodes.firstWhere(
            (e) => e['episode_number'] == lastWatchedEpInSeason + 1,
            orElse: () => null,
          );

          if (nextEp != null) {
            displayLabel =
                "S${nextEp['season_number']} E${nextEp['episode_number']}";
            displayTitle = nextEp['name'] ?? "";
            displayAirDate = nextEp['air_date'];
            isSeriesCompleted = false; 
          } else {
            final urlNextSeason =
                "https://api.themoviedb.org/3/tv/$seriesId/season/${targetSeason + 1}?api_key=$tmdbApiKey&language=en-US";
            final resNextSeason = await http.get(Uri.parse(urlNextSeason));

            if (resNextSeason.statusCode == 200) {
              final nextSData = json.decode(resNextSeason.body);
              final List nextEpisodes = nextSData['episodes'] ?? [];
              if (nextEpisodes.isNotEmpty) {
                final firstEp = nextEpisodes[0]; 
                displayLabel =
                    "S${firstEp['season_number']} E${firstEp['episode_number']}";
                displayTitle = firstEp['name'] ?? "";
                displayAirDate = firstEp['air_date'];
                isSeriesCompleted = false; 
              } else {
                if (maxSeason > 0) isSeriesCompleted = true;
              }
            } else {
              if (maxSeason > 0) {
                displayLabel = "S$maxSeason E$maxEpisode";
                isSeriesCompleted = true;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Errore calcolo prossimo episodio: $e");
        if (maxSeason > 0) displayLabel = "S$maxSeason E$maxEpisode";
      }
    } else {
      if (maxSeason > 0) displayLabel = "S$maxSeason E$maxEpisode";
    }

    double watchedHours = watchedMinutes / 60.0;
    double totalSeriesHours = await getSeriesTotalRuntimeFromApi(seriesName);

    double newPercentage = totalSeriesHours > 0
        ? watchedHours / totalSeriesHours
        : 0;

    if (newPercentage >= 0.99) {
      newPercentage = 1.0;
    }
    if (newPercentage > 1.0) newPercentage = 1.0;

    await seriesRef.set({
      'totalHours': watchedHours,
      'percentage': newPercentage,
      'episode': displayLabel,
      'seriesDuration': totalSeriesHours,
      'lastEpisodeTitle': displayTitle,
      'completed': isSeriesCompleted,
      'nextEpisodeAirDate': displayAirDate,
    }, SetOptions(merge: true));

    await calculatePureObsession(seriesName);
    await calculateWeekendWarrior();
    await updateSeriesStreak();
    await calculateNightOwl();
    await updateGenreCount();
  }

  static Future<double> getSeriesTotalRuntimeFromApi(String seriesName) async {
    try {
      final searchUrl =
          "https://api.themoviedb.org/3/search/tv?api_key=$tmdbApiKey&query=${Uri.encodeComponent(seriesName)}";
      final searchRes = await http.get(Uri.parse(searchUrl));

      if (searchRes.statusCode == 200) {
        final searchData = json.decode(searchRes.body);
        if (searchData['results'].isNotEmpty) {
          final int seriesId = searchData['results'][0]['id'];

          final detailRes = await http.get(
            Uri.parse(
              "https://api.themoviedb.org/3/tv/$seriesId?api_key=$tmdbApiKey&language=it-IT",
            ),
          );
          final data = json.decode(detailRes.body);

          int episodesCount = data['number_of_episodes'] ?? 0;
          int runtime = 45;

          if (data['episode_run_time'] != null &&
              (data['episode_run_time'] as List).isNotEmpty) {
            runtime = data['episode_run_time'][0];
          }

          return (episodesCount * runtime) / 60.0;
        }
      }
    } catch (e) {
      debugPrint("Errore calcolo runtime totale TMDB: $e");
    }
    return 1.0;
  }

  static Future<void> calculatePureObsession(String seriesName) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final seriesRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('series')
        .doc(seriesName);

    List<Map<String, dynamic>> watchedEpisodes = [];
    final seasonsSnap = await seriesRef.collection('seasons').get();

    for (var season in seasonsSnap.docs) {
      final epSnap = await season.reference
          .collection('episodes')
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
        final previousTimestamp =
            watchedEpisodes[i - 1]['timestamp'] as Timestamp?;

        if (currentTimestamp != null && previousTimestamp != null) {
          DateTime currentTime = currentTimestamp.toDate();
          DateTime previousTime = previousTimestamp.toDate();
          double previousRuntime = (watchedEpisodes[i - 1]['runtime'] ?? 0)
              .toDouble();

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
    double actualRecord = (userSnap.data()?['maxConsecutiveHours'] ?? 0)
        .toDouble();

    if (maxSessionHours > actualRecord) {
      await userDoc.update({'maxConsecutiveHours': maxSessionHours});
    }
  }

  static Future<void> calculateWeekendWarrior() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, double> weekendGroups = {};

    final seriesSnap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('series')
        .get();

    for (var seriesDoc in seriesSnap.docs) {
      final seasonsSnap = await seriesDoc.reference.collection('seasons').get();
      for (var seasonDoc in seasonsSnap.docs) {
        final episodesSnap = await seasonDoc.reference
            .collection('episodes')
            .where('watched', isEqualTo: true)
            .get();

        for (var epDoc in episodesSnap.docs) {
          final data = epDoc.data();
          if (data['timestamp'] != null) {
            DateTime date = (data['timestamp'] as Timestamp).toDate();

            if (date.weekday >= DateTime.friday &&
                date.weekday <= DateTime.sunday) {
              String weekendId =
                  "${date.year}-${_getIdWeekNumber(date)}"; 

              double runtime = (data['runtime'] ?? 0).toDouble();
              weekendGroups[weekendId] =
                  (weekendGroups[weekendId] ?? 0) + runtime;
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

  static int _getIdWeekNumber(DateTime date) {
    int daysSinceJan1 = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((daysSinceJan1 + DateTime(date.year, 1, 1).weekday - 1) / 7)
            .floor() +
        1;
  }

  static Future<void> updateSeriesStreak() async {
    final fbUser = auth.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;

    final userRef = _db.collection('users').doc(fbUser.uid);
    final doc = await userRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    int currentStreak = data['seriesStreak'] ?? 0;
    Timestamp? lastTimestamp = data['lastViewDate'] as Timestamp?;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastTimestamp != null) {
      final lastDate = lastTimestamp.toDate();
      final lastView = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(lastView).inDays;

      if (diff == 1) {
        currentStreak += 1;
      } else if (diff > 1) {
        currentStreak = 1;
      } else if (diff == 0) {
        return;
      }
    } else {
      currentStreak = 0;
    }

    await userRef.update({
      'seriesStreak': currentStreak,
      'lastViewDate': Timestamp.fromDate(now),
    });

    if (currentUser != null) {
      currentUser!.seriesStreak = currentStreak;
      currentUser!.lastViewDate = now;
    }
  }

  static UserBadge getStreakTarget(double currentStreak) {
    UserBadge target = streakMilestones.first;
    for (var badge in streakMilestones) {
      if (currentStreak >= badge.targetHours) {
        if (badge.nextId != null) {
          target = streakMilestones.firstWhere(
            (b) => b.id == badge.nextId,
            orElse: () => badge,
          );
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

  static UserBadge getCompletionistTarget(double currentCompleted) {
    UserBadge target = completionistMilestones.first;
    for (var badge in completionistMilestones) {
      if (currentCompleted >= badge.targetHours) {
        if (badge.nextId != null) {
          target = completionistMilestones.firstWhere(
            (b) => b.id == badge.nextId,
            orElse: () => badge,
          );
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

  static Future<void> calculateNightOwl() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double totalNightMinutes = 0;
    final seriesSnap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('series')
        .get();

    for (var seriesDoc in seriesSnap.docs) {
      final seasonsSnap = await seriesDoc.reference.collection('seasons').get();
      for (var seasonDoc in seasonsSnap.docs) {
        final episodesSnap = await seasonDoc.reference
            .collection('episodes')
            .where('watched', isEqualTo: true)
            .get();

        for (var epDoc in episodesSnap.docs) {
          final data = epDoc.data();
          if (data['timestamp'] != null) {
            DateTime date = (data['timestamp'] as Timestamp).toDate();
            if (date.hour >= 0 && date.hour < 4) {
              totalNightMinutes += (data['runtime'] ?? 0).toDouble();
            }
          }
        }
      }
    }

    double nightHours = totalNightMinutes / 60.0;
    await _db.collection('users').doc(user.uid).set({
      'nightOwlHours': nightHours,
    }, SetOptions(merge: true));
  }

  static UserBadge getNightOwlTarget(double currentNightHours) {
    UserBadge target = nightOwlMilestones.first;
    for (var badge in nightOwlMilestones) {
      if (currentNightHours >= badge.targetHours) {
        if (badge.nextId != null) {
          target = nightOwlMilestones.firstWhere(
            (b) => b.id == badge.nextId,
            orElse: () => badge,
          );
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

  static Future<void> claimBadge(String badgeId) async {
    final uid = auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      'claimedBadgeIds': FieldValue.arrayUnion([badgeId]),
    });
  }

  static Future<bool> isSeriesTracked(String seriesName) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await _db
          .collection('users')
          .doc(user.uid)
          .collection('series')
          .doc(seriesName)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint("Errore controllo serie: $e");
      return false;
    }
  }

  static Future<void> updateGenreCount() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null || userSeries.isEmpty) return;

    Set<String> uniqueGenres = {};

    for (var series in userSeries) {
      if (series.percentage > 0) {
        List<String> genres = await _fetchGenresForSeries(series.id);
        uniqueGenres.addAll(genres);
      }
    }

    await _db.collection('users').doc(user.uid).update({
      'uniqueGenresCount': uniqueGenres.length,
    });
  }

  static Future<List<String>> _fetchGenresForSeries(int seriesId) async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://api.themoviedb.org/3/tv/$seriesId?api_key=$tmdbApiKey",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['genres'] as List)
            .map((g) => g['name'].toString())
            .toList();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  static Future<Map<String, dynamic>> _fetchAndCalculateSeriesData(
    int seriesId,
  ) async {
    final String url =
        "https://api.themoviedb.org/3/tv/$seriesId?api_key=$tmdbApiKey&language=en-US";

    double totalDurationHours = 0.0;
    String posterUrl = "";
    int avgRuntime = 45; 

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['poster_path'] != null) {
          posterUrl = "https://image.tmdb.org/t/p/w500${data['poster_path']}";
        }

        int numberOfEpisodes = data['number_of_episodes'] ?? 0;

        if (data['episode_run_time'] != null &&
            (data['episode_run_time'] as List).isNotEmpty) {
          avgRuntime = data['episode_run_time'][0];
        }

        int totalMinutes = numberOfEpisodes * avgRuntime;
        totalDurationHours = totalMinutes / 60.0;
      }
    } catch (e) {
      debugPrint("Errore API TMDB: $e");
    }

    return {
      'imageUrl': posterUrl,
      'seriesDuration': totalDurationHours,
      'averageRuntime': avgRuntime, 
    };
  }

  static Future<void> toggleEpisodeWatched({
    required String seriesName,
    required int seriesId, 
    required int seasonNum,
    required int episodeNum,
    required String episodeTitle,
    required bool isWatched,
  }) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final seriesRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('series')
        .doc(seriesName);

    final seriesDoc = await seriesRef.get();
    int runtimeToSave = 45;

    if (!seriesDoc.exists) {
      final apiData = await _fetchAndCalculateSeriesData(seriesId);
      runtimeToSave = apiData['averageRuntime'];

      await seriesRef.set({
        'id': seriesId,
        'imageUrl': apiData['imageUrl'],
        'seriesDuration': apiData['seriesDuration'],
        'averageRuntime': runtimeToSave,
        'addedDate': FieldValue.serverTimestamp(),
        'episode': "S1 E1",
        'percentage': 0.0,
        'totalHours': 0.0,
        'isFavorite': false,
        'completed': false,
      }, SetOptions(merge: true));
    } else {
      final data = seriesDoc.data();
      if (data != null && data.containsKey('averageRuntime')) {
        runtimeToSave = (data['averageRuntime'] as num).toInt();
      } else {
        final apiData = await _fetchAndCalculateSeriesData(seriesId);
        runtimeToSave = apiData['averageRuntime'];
        await seriesRef.update({'averageRuntime': runtimeToSave});
      }
    }

    final seasonRef = seriesRef.collection('seasons').doc('Season $seasonNum');
    final episodeRef = seasonRef
        .collection('episodes')
        .doc('Episode $episodeNum');

    if (isWatched) {
      await seasonRef.set({
        'season_number': seasonNum,
      }, SetOptions(merge: true));
      await episodeRef.set({
        'episode_number': episodeNum,
        'runtime': runtimeToSave,
        'timestamp': FieldValue.serverTimestamp(),
        'watched': true,
        'episode_title': episodeTitle,
      }, SetOptions(merge: true));
    } else {
      await episodeRef.update({'watched': false});
    }

    await syncSeriesTotalHours(seriesName);
  }

  static Future<bool> isSeriesFavorite(String seriesName) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await _db
          .collection('users')
          .doc(user.uid)
          .collection('series')
          .doc(seriesName)
          .get();

      if (doc.exists) {
        return doc.data()?['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setSeriesFavorite(
    String seriesName,
    int seriesId,
    bool isFavorite,
  ) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final seriesRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('series')
        .doc(seriesName);

    final docSnapshot = await seriesRef.get();

    if (!docSnapshot.exists) {
      if (!isFavorite) return;

      try {
        final Map<String, dynamic> apiData = await _fetchAndCalculateSeriesData(
          seriesId,
        );

        await seriesRef.set({
          'id': seriesId,
          'imageUrl': apiData['imageUrl'],
          'seriesDuration': apiData['seriesDuration'],
          'averageRuntime': apiData['averageRuntime'],
          'addedDate': FieldValue.serverTimestamp(),
          'episode': "S1 E1",
          'percentage': 0.0,
          'totalHours': 0.0,
          'isFavorite': isFavorite,
          'completed': false,
        }, SetOptions(merge: true));

        userSeries.add(
          Series(
            id: seriesId,
            name: seriesName,
            imageUrl: apiData['imageUrl'],
            percentage: 0.0,
            totalHours: 0.0,
            seriesDuration: apiData['seriesDuration'],
            episode: "S1 E1",
            isFavorite: isFavorite,
          ),
        );
      } catch (e) {
        debugPrint("Errore creazione serie preferita: $e");
      }
    } else {
      final data = docSnapshot.data();
      double currentTotalHours = (data?['totalHours'] ?? 0).toDouble();

      if (isFavorite == false && currentTotalHours == 0) {
        await seriesRef.delete();
        userSeries.removeWhere((s) => s.name == seriesName);
      } else {
        await seriesRef.update({'isFavorite': isFavorite});
        final index = userSeries.indexWhere((s) => s.name == seriesName);
        if (index != -1) {
          userSeries[index].isFavorite = isFavorite;
        }
      }
    }
  }

  static Future<NextEpisodeInfo?> fetchNextEpisode(int seriesId) async {
    final String url =
        "https://api.themoviedb.org/3/tv/$seriesId?api_key=$tmdbApiKey&language=en-US";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nextEpData = data['next_episode_to_air'];

        if (nextEpData == null) return null;

        final String? airDateStr = nextEpData['air_date'];
        if (airDateStr == null) return null;

        final airDate = DateTime.parse(airDateStr);
        final now = DateTime.now();

        if (airDate.isBefore(DateTime(now.year, now.month, now.day))) {
          return null;
        }

        return NextEpisodeInfo(
          name: nextEpData['name'] ?? "TBA",
          episodeLabel:
              "S${nextEpData['season_number']} E${nextEpData['episode_number']}",
          airDate: airDate,
          stillUrl: nextEpData['still_path'] != null
              ? "https://image.tmdb.org/t/p/w500${nextEpData['still_path']}"
              : null,
        );
      }
    } catch (e) {
      debugPrint("Errore fetchNextEpisode per ID $seriesId: $e");
    }
    return null;
  }

  static Future<List<double>> getChartData(ChartPeriod period) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    List<double> dataPoints = [];

    if (period == ChartPeriod.year) {
      dataPoints = List.filled(12, 0.0);
    } else if (period == ChartPeriod.month) {
      int currentDay = now.day;
      dataPoints = List.filled(currentDay, 0.0);
    } else {
      dataPoints = List.filled(7, 0.0);
    }

    try {
      final seriesSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('series')
          .get();
      for (var seriesDoc in seriesSnap.docs) {
        final seasonsSnap = await seriesDoc.reference
            .collection('seasons')
            .get();
        for (var seasonDoc in seasonsSnap.docs) {
          final episodesSnap = await seasonDoc.reference
              .collection('episodes')
              .where('watched', isEqualTo: true)
              .get();

          for (var epDoc in episodesSnap.docs) {
            final data = epDoc.data();
            if (data['timestamp'] == null) continue;

            DateTime date = (data['timestamp'] as Timestamp).toDate();
            double hours = (data['runtime'] ?? 0) / 60.0;

            if (period == ChartPeriod.year && date.year == now.year) {
              dataPoints[date.month - 1] += hours;
            } else if (period == ChartPeriod.month &&
                date.year == now.year &&
                date.month == now.month) {
              dataPoints[date.day - 1] += hours;
            } else if (period == ChartPeriod.week) {
              final diff = now.difference(date).inDays;
              if (diff >= 0 && diff < 7) dataPoints[6 - diff] += hours;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Errore: $e");
    }
    return dataPoints;
  }

  static Future<Map<ChartPeriod, List<double>>> getAllChartData() async {
    final weekData = await getChartData(ChartPeriod.week);
    final monthData = await getChartData(ChartPeriod.month);
    final yearData = await getChartData(ChartPeriod.year);

    return {
      ChartPeriod.week: weekData,
      ChartPeriod.month: monthData,
      ChartPeriod.year: yearData,
    };
  }
}