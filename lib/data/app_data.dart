import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../models/series.dart';
import '../models/user_badge.dart';
import '../services/tmdb_service.dart';
import '../services/stats_logic.dart';

enum ChartPeriod { year, month, week }

class AppData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static const String tmdbApiKey = "1a4c56551c8917b157c4a6fdd2fca54d";
  static const Color primaryColor = Color(0xFF791209);
  static const Color accentColor = Color(0xFF364156); 
  static const Color backgroundColor = Color(0xFFEEF0E9);
  static const Color avatarColor = Color(0xFF4A5568);
  static const Color whiteColor = Colors.white;

  static List<Series> userSeries = [];
  static List<UserBadge> userBadges = [];
  static User? currentUser;

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

    StatsLogic.generateUserBadges(currentUser, userSeries);
  }

  static void resetData() {
    userSeries.clear();
    userBadges.clear();
    currentUser = null;
  }

  static Future<void> _populateFirstTime(auth.User fbUser, DocumentReference docRef) async {
    await docRef.set({
      'name': fbUser.displayName ?? "User",
      'totalHoursWatched': 0.0,
      'maxConsecutiveHours': 0.0,
      'weekendHours': 0.0,
      'nightOwlHours': 0.0,
    }, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot> userStream() {
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return const Stream.empty();
    return _db.collection('users').doc(firebaseUser.uid).snapshots();
  }

  static Stream<QuerySnapshot> seriesStream() {
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return const Stream.empty();
    return _db.collection('users').doc(firebaseUser.uid).collection('series').snapshots();
  }

  static double getTotalWatchTimeHours() {
    if (userSeries.isEmpty) return 0.0;
    double total = 0;
    for (var series in userSeries) {
      total += (series.totalHours);
    }
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _db.collection('users').doc(firebaseUser.uid).update({'totalHoursWatched': total});
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

  static Future<void> claimBadge(String badgeId) async {
    final uid = auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'claimedBadgeIds': FieldValue.arrayUnion([badgeId]),
    });
  }

  static Future<void> setSeriesFavorite(String seriesName, int seriesId, bool isFavorite) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final seriesRef = _db.collection('users').doc(user.uid).collection('series').doc(seriesName);
    final docSnapshot = await seriesRef.get();

    if (!docSnapshot.exists) {
      if (!isFavorite) return;
      try {
        final apiData = await TmdbService.fetchAndCalculateSeriesData(seriesId);

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

        userSeries.add(Series(
            id: seriesId,
            name: seriesName,
            imageUrl: apiData['imageUrl'],
            percentage: 0.0,
            totalHours: 0.0,
            seriesDuration: apiData['seriesDuration'],
            episode: "S1 E1",
            isFavorite: isFavorite));
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
}