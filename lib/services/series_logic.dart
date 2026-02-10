import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../services/tmdb_service.dart';
import 'stats_logic.dart';

class SeriesLogic {
  static FirebaseFirestore _db = FirebaseFirestore.instance;
  static http.Client httpClient =
      http.Client(); //Need for test with fake client
  @visibleForTesting
  static set db(FirebaseFirestore mockDb) => _db = mockDb;
  static String? _getUid() {
    try {
      return auth.FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }

  static Future<void> syncSeriesTotalHours(
    String seriesName, {
    String? userUid,
  }) async {
    final String? uid = userUid ?? _getUid();
    if (uid == null) return;

    final seriesRef = _db
        .collection('users')
        .doc(uid)
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
            "https://api.themoviedb.org/3/tv/$seriesId/season/$targetSeason?api_key=${AppData.tmdbApiKey}&language=en-US";
        final resSeason = await httpClient.get(Uri.parse(urlSeason));

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
                "https://api.themoviedb.org/3/tv/$seriesId/season/${targetSeason + 1}?api_key=${AppData.tmdbApiKey}&language=en-US";
            final resNextSeason = await httpClient.get(
              Uri.parse(urlNextSeason),
            );

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
    double totalSeriesHours = await TmdbService.getSeriesTotalRuntimeFromApi(
      seriesName,
    );

    double newPercentage = totalSeriesHours > 0
        ? watchedHours / totalSeriesHours
        : 0;
    if (newPercentage >= 0.99) newPercentage = 1.0;
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

    await StatsLogic.calculatePureObsession(seriesName);
    await StatsLogic.calculateWeekendWarrior();
    await updateSeriesStreak();
    await StatsLogic.calculateNightOwl();
    await updateGenreCount();
  }

  static Future<void> toggleEpisodeWatched({
    required String seriesName,
    required int seriesId,
    required int seasonNum,
    required int episodeNum,
    required String episodeTitle,
    required bool isWatched,
    String? userUid,
  }) async {
    final String? uid = userUid ?? _getUid();
    if (uid == null) return;
    final seriesRef = _db
        .collection('users')
        .doc(uid)
        .collection('series')
        .doc(seriesName);
    final seriesDoc = await seriesRef.get();
    int runtimeToSave = 45;

    if (!seriesDoc.exists) {
      final apiData = await TmdbService.fetchAndCalculateSeriesData(seriesId);
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
        final apiData = await TmdbService.fetchAndCalculateSeriesData(seriesId);
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

    await syncSeriesTotalHours(seriesName, userUid: uid);
  }

  static Future<void> updateSeriesStreak({String? userUid}) async {
    final String? uid = userUid ?? _getUid();
    if (uid == null) return;

    final userRef = _db.collection('users').doc(uid);
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
      }
    } else {
      currentStreak = 0;
    }

    await userRef.update({
      'seriesStreak': currentStreak,
      'lastViewDate': Timestamp.fromDate(now),
    });
  }

  static Future<void> updateGenreCount({String? userUid}) async {
    final String? uid = userUid ?? _getUid();
    if (uid == null) return;

    final seriesSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('series')
        .get();
    Set<String> uniqueGenres = {};

    for (var doc in seriesSnap.docs) {
      double percentage = (doc.data()['percentage'] ?? 0).toDouble();
      int id = doc.data()['id'] ?? 0;
      if (percentage > 0 && id != 0) {
        List<String> genres = await TmdbService.fetchGenresForSeries(id);
        uniqueGenres.addAll(genres);
      }
    }

    await _db.collection('users').doc(uid).update({
      'uniqueGenresCount': uniqueGenres.length,
    });
  }

  static Future<bool> isSeriesFavorite(
    String seriesName, {
    String? userUid,
  }) async {
    final String? uid = userUid ?? _getUid();
    if (uid == null) return false;
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
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
}
