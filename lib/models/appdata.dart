import 'next_episode_info.dart';
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
  static const String tmdbApiKey = "1a4c56551c8917b157c4a6fdd2fca54d";
  static List<Series> userSeries = [];
  static List<UserBadge> userBadges = [];
  static User? currentUser;
  static const Color primaryColor = Color(0xFF791209);     // Bordeaux
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

  static Future<void> initializeData() async {
    userSeries.clear();
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final userDoc = _db.collection('users').doc(firebaseUser.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await _populateFirstTime(firebaseUser, userDoc);
    } else {
      final data = snapshot.data()!; 

      String? originalPhotoUrl = data['photoUrl'] ?? firebaseUser.photoURL;
      String? highResPhotoUrl = originalPhotoUrl;

      // Se l'URL proviene da Google, aumentiamo la risoluzione
      if (originalPhotoUrl != null && originalPhotoUrl.contains('googleusercontent.com')) {
        // Sostituisce la dimensione s96-c (o simili) con s400-c (400px)
        highResPhotoUrl = originalPhotoUrl.replaceFirst('s96-c', 's400-c');
      }
      
      currentUser = User(
        name: data['name'] ?? firebaseUser.displayName ?? "User",
        totalHoursWatched: (data['totalHoursWatched'] ?? 0).toDouble(),
        maxConsecutiveHours: (data['maxConsecutiveHours'] ?? 0).toDouble(), // Fix cast
        weekendHours:( data['weekendHours'] ?? 0).toDouble(),
        notification: data['notification'] ?? true,
        photoUrl: highResPhotoUrl,
      );

      final seriesSnap = await userDoc.collection('series').get();
      for (var doc in seriesSnap.docs) {
        final sData = doc.data();
        
        userSeries.add(Series(
          id: sData['id'] ?? 0,
          name: doc.id,
          imageUrl: doc['imageUrl'],
          percentage: (doc['percentage'] ?? 0).toDouble(),
          totalHours: (doc['totalHours'] ?? 0).toDouble(),
          episode: doc['episode'] ?? "",
          lastEpisodeTitle: sData['lastEpisodeTitle'] ?? "",
          nextEpisodeAirDate: sData['nextEpisodeAirDate'],
          seriesDuration: (doc['seriesDuration'] ?? 0).toDouble(),
          isFavorite: doc['isFavorite'] ?? false, 
          completed: sData['completed'] ?? false,
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

  }

  static Future<String> fetchImageUrl(String name) async {
    final String url = "https://api.themoviedb.org/3/search/tv?api_key=$tmdbApiKey&query=${Uri.encodeComponent(name)}&language=it-IT";

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

  // --- FUNZIONE AGGIORNATA: Calcola totali, PROSSIMO episodio e STATO COMPLETATO ---
  static Future<void> syncSeriesTotalHours(String seriesName) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final seriesRef = _db.collection('users').doc(user.uid).collection('series').doc(seriesName);

    double watchedMinutes = 0;
    
    // Variabili per l'ultimo visto (Local DB)
    int maxSeason = -1;
    int maxEpisode = -1;
    
    // Variabili per il prossimo da vedere (Output finale)
    String displayLabel = "S1 E1"; 
    String displayTitle = ""; 
    String? displayAirDate;
    
    bool isSeriesCompleted = false; 

    // 1. Recuperiamo ID Serie e Statistiche Viste
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

        int sNum = data['season_number'] ?? int.tryParse(seasonDoc.id.split(' ').last) ?? 0;
        int eNum = data['episode_number'] ?? 0;

        if (sNum > maxSeason) {
          maxSeason = sNum;
          maxEpisode = eNum;
        } else if (sNum == maxSeason && eNum > maxEpisode) {
          maxEpisode = eNum;
        }
      }
    }

    // 2. LOGICA PROSSIMO EPISODIO: Interroghiamo TMDB
    if (seriesId != 0) {
      try {
        int targetSeason = maxSeason < 1 ? 1 : maxSeason;
        int lastWatchedEpInSeason = maxEpisode < 1 ? 0 : maxEpisode;

        // Chiamata API per ottenere i dettagli della stagione corrente (o target)
        final urlSeason = "https://api.themoviedb.org/3/tv/$seriesId/season/$targetSeason?api_key=$tmdbApiKey&language=en-US";
        final resSeason = await http.get(Uri.parse(urlSeason));

        if (resSeason.statusCode == 200) {
          final sData = json.decode(resSeason.body);
          final List episodes = sData['episodes'] ?? [];

          // Cerchiamo l'episodio successivo nella lista
          var nextEp = episodes.firstWhere(
            (e) => e['episode_number'] == lastWatchedEpInSeason + 1, 
            orElse: () => null
          );

          if (nextEp != null) {
            // Caso A: C'è un episodio successivo in questa stagione
            displayLabel = "S${nextEp['season_number']} E${nextEp['episode_number']}";
            displayTitle = nextEp['name'] ?? "";
            displayAirDate = nextEp['air_date'];
            isSeriesCompleted = false; // C'è ancora da vedere
          } else {
            // Caso B: Stagione finita? Proviamo la stagione successiva, Episodio 1
            final urlNextSeason = "https://api.themoviedb.org/3/tv/$seriesId/season/${targetSeason + 1}?api_key=$tmdbApiKey&language=en-US";
            final resNextSeason = await http.get(Uri.parse(urlNextSeason));
            
            if (resNextSeason.statusCode == 200) {
              final nextSData = json.decode(resNextSeason.body);
              final List nextEpisodes = nextSData['episodes'] ?? [];
              if (nextEpisodes.isNotEmpty) {
                 final firstEp = nextEpisodes[0]; // Episodio 1
                 displayLabel = "S${firstEp['season_number']} E${firstEp['episode_number']}";
                 displayTitle = firstEp['name'] ?? "";
                 displayAirDate = firstEp['air_date'];
                 isSeriesCompleted = false; // C'è una nuova stagione
              } else {
                 // Stagione successiva esiste ma è vuota (raro, ma possibile) -> Completata
                 if (maxSeason > 0) isSeriesCompleted = true;
              }
            } else {
              // Caso C: Serie finita (Nessuna stagione successiva trovata API 404)
              if (maxSeason > 0) {
                 // Manteniamo l'etichetta dell'ultimo visto perché non c'è un "prossimo"
                 displayLabel = "S$maxSeason E$maxEpisode";
                 
                 // --- SETTIAMO A TRUE ---
                 isSeriesCompleted = true; 
                 // -----------------------
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

    double newPercentage = totalSeriesHours > 0 ? watchedHours / totalSeriesHours : 0;
    
    // Logica extra di sicurezza: se la percentuale è > 0.99, probabilmente è finita anche se l'API ha fallito
    if (newPercentage >= 0.99) {
      newPercentage = 1.0;
      // Opzionale: puoi forzare isSeriesCompleted = true qui se ti fidi più della percentuale
    }
    if (newPercentage > 1.0) newPercentage = 1.0; 

    // Aggiorniamo il documento principale della serie
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
  }

  static Future<double> getSeriesTotalRuntimeFromApi(String seriesName) async {
    try {
      final searchUrl = "https://api.themoviedb.org/3/search/tv?api_key=$tmdbApiKey&query=${Uri.encodeComponent(seriesName)}";
      final searchRes = await http.get(Uri.parse(searchUrl));
      
      if (searchRes.statusCode == 200) {
        final searchData = json.decode(searchRes.body);
        if (searchData['results'].isNotEmpty) {
          final int seriesId = searchData['results'][0]['id'];

          final detailRes = await http.get(Uri.parse("https://api.themoviedb.org/3/tv/$seriesId?api_key=$tmdbApiKey&language=it-IT"));
          final data = json.decode(detailRes.body);

          int episodesCount = data['number_of_episodes'] ?? 0;
          int runtime = 45; 

          if (data['episode_run_time'] != null && (data['episode_run_time'] as List).isNotEmpty) {
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
    double actualRecord = (userSnap.data()?['maxConsecutiveHours'] ?? 0).toDouble();

    if (maxSessionHours > actualRecord) {
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
            
              String weekendId = "${date.year}-${_getIdWeekNumber(date)}"; // ex. 2023-43
              
              double runtime = (data['runtime'] ?? 0).toDouble();
              weekendGroups[weekendId] = (weekendGroups[weekendId] ?? 0) + runtime;
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

  static int _getIdWeekNumber(DateTime date) { // return the weekend number from 1 to 52
    int daysSinceJan1 = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((daysSinceJan1 + DateTime(date.year, 1, 1).weekday - 1) / 7).floor() + 1;
    //dateTime(..).weekday returns the day of the week as monday, Tuesday etc..
  }

  
  // 1. Controlla se la serie è già tracciata
  static Future<bool> isSeriesTracked(String seriesName) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Verifica l'esistenza del documento nella raccolta 'series'
      // Nota: Uso 'series' perché è la raccolta che ProfileScreen ascolta.
      // Se vuoi cambiarla in 'favorites_series', cambia la stringa qui sotto.
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

  // --- NUOVA FUNZIONE PRIVATA DI SUPPORTO (Logica API TMDB) ---
  // Questa funzione è autonoma e non dipende da altri helper
  static Future<Map<String, dynamic>> _fetchAndCalculateSeriesData(int seriesId) async {
    final String url = "https://api.themoviedb.org/3/tv/$seriesId?api_key=$tmdbApiKey&language=en-US";
    
    double totalDurationHours = 0.0;
    String posterUrl = "";
    int avgRuntime = 45; // Default

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['poster_path'] != null) {
          posterUrl = "https://image.tmdb.org/t/p/w500${data['poster_path']}";
        }

        int numberOfEpisodes = data['number_of_episodes'] ?? 0;
        
        // Recuperiamo il tempo medio ufficiale della serie
        if (data['episode_run_time'] != null && (data['episode_run_time'] as List).isNotEmpty) {
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
      'averageRuntime': avgRuntime, // <--- NUOVO DATO
    };
  }
// --- NUOVA FUNZIONE: Segna/Deseleziona episodio come visto ---
  static Future<void> toggleEpisodeWatched({
    required String seriesName,
    required int seriesId, // <--- Importante: Ora ci serve l'ID per crearla se non esiste
    required int seasonNum,
    required int episodeNum,
    required String episodeTitle,
    required bool isWatched,
  }) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final seriesRef = _db.collection('users').doc(user.uid).collection('series').doc(seriesName);
    
    // 1. Check preliminare: Se la serie non esiste nel DB, dobbiamo crearla come "Non Preferita"
    final seriesDoc = await seriesRef.get();
    int runtimeToSave = 45;

    if (!seriesDoc.exists) {
      // CREAZIONE AUTOMATICA (Non preferita)
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
      // Se esiste, recuperiamo il runtime medio salvato
      final data = seriesDoc.data();
      if (data != null && data.containsKey('averageRuntime')) {
        runtimeToSave = (data['averageRuntime'] as num).toInt();
      } else {
        // Fallback se manca il campo nel vecchio record
         final apiData = await _fetchAndCalculateSeriesData(seriesId);
         runtimeToSave = apiData['averageRuntime'];
         await seriesRef.update({'averageRuntime': runtimeToSave});
      }
    }

    // 2. Procediamo normalmente a salvare l'episodio
    final seasonRef = seriesRef.collection('seasons').doc('Season $seasonNum');
    final episodeRef = seasonRef.collection('episodes').doc('Episode $episodeNum');

    if (isWatched) {
      await seasonRef.set({'season_number': seasonNum}, SetOptions(merge: true));
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
      
      // Se esiste, ritorniamo il valore del campo isFavorite, altrimenti false
      if (doc.exists) {
        return doc.data()?['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setSeriesFavorite(String seriesName, int seriesId, bool isFavorite) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final seriesRef = _db.collection('users').doc(user.uid).collection('series').doc(seriesName);

    // Controlliamo se la serie esiste già
    final docSnapshot = await seriesRef.get();

    if (!docSnapshot.exists) {
      // CASO A: La serie non esiste -> La creiamo
      try {
        final Map<String, dynamic> apiData = await _fetchAndCalculateSeriesData(seriesId);
        
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

        // Aggiorniamo lista locale
        userSeries.add(Series(
          id: seriesId,
          name: seriesName,
          imageUrl: apiData['imageUrl'],
          percentage: 0.0,
          totalHours: 0.0,
          seriesDuration: apiData['seriesDuration'],
          episode: "S1 E1",
          isFavorite: isFavorite,
        ));
      } catch (e) {
        debugPrint("Errore creazione serie preferita: $e");
      }
    } else {
      // CASO B: La serie esiste -> Aggiorniamo solo il flag isFavorite
      await seriesRef.update({'isFavorite': isFavorite});
      
      // Aggiorniamo lista locale
      final index = userSeries.indexWhere((s) => s.name == seriesName);
      if (index != -1) {
        userSeries[index].isFavorite = isFavorite;
      }
    }
  }

  static Future<NextEpisodeInfo?> fetchNextEpisode(int seriesId) async {
    // 1. Usiamo l'endpoint dei dettagli generali, NON un endpoint specifico che non esiste
    final String url = "https://api.themoviedb.org/3/tv/$seriesId?api_key=$tmdbApiKey&language=en-US";
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 2. Cerchiamo il campo specifico 'next_episode_to_air'
        final nextEpData = data['next_episode_to_air'];

        // Se è null, la serie è finita o non ha date annunciate
        if (nextEpData == null) return null;

        final String? airDateStr = nextEpData['air_date'];
        if (airDateStr == null) return null;

        final airDate = DateTime.parse(airDateStr);
        final now = DateTime.now();
        
        // Controllo opzionale: mostriamo solo se è da oggi in poi
        // (DateTime(now.year...) serve per azzerare l'ora e confrontare solo i giorni)
        if (airDate.isBefore(DateTime(now.year, now.month, now.day))) {
           return null;
        }

        return NextEpisodeInfo(
          name: nextEpData['name'] ?? "TBA",
          episodeLabel: "S${nextEpData['season_number']} E${nextEpData['episode_number']}",
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
  
}