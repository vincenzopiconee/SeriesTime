import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import '../models/user_badge.dart';
import '../models/series.dart';
import '../models/user.dart';
import '../data/badge_definitions.dart';
import '../data/app_data.dart';

class StatsLogic {
  static FirebaseFirestore _db = FirebaseFirestore.instance;

  @visibleForTesting
  static set db(FirebaseFirestore mockDb) => _db = mockDb;

  static String? _getUid() {
    try {
      return auth.FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }

  static UserBadge getMarathonerTarget(double totalHours) {
    return _findTarget(BadgeDefinitions.marathonerMilestones, totalHours);
  }

  static UserBadge getObsessionTarget(double currentObsessionHours) {
    return _findTarget(
      BadgeDefinitions.obsessionMilestones,
      currentObsessionHours,
    );
  }

  static UserBadge getWeekendTarget(double currentWeekendHours) {
    return _findTarget(BadgeDefinitions.weekendMilestones, currentWeekendHours);
  }

  static UserBadge getStreakTarget(double currentStreak) {
    return _findTarget(BadgeDefinitions.streakMilestones, currentStreak);
  }

  static UserBadge getCompletionistTarget(double currentCompleted) {
    return _findTarget(
      BadgeDefinitions.completionistMilestones,
      currentCompleted,
    );
  }

  static UserBadge getNightOwlTarget(double currentNightHours) {
    return _findTarget(BadgeDefinitions.nightOwlMilestones, currentNightHours);
  }

  static UserBadge getGenreTarget(int currentCount) {
    return _findTarget(
      BadgeDefinitions.genreMilestones,
      currentCount.toDouble(),
    );
  }

  static UserBadge _findTarget(
    List<UserBadge> milestones,
    double currentValue,
  ) {
    UserBadge target = milestones.first;
    for (var badge in milestones) {
      if (currentValue >= badge.targetHours) {
        if (badge.nextId != null) {
          target = milestones.firstWhere(
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

  static List<UserBadge> generateUserBadges(
    User? currentUser,
    List<Series> userSeries,
  ) {
    List<UserBadge> badges = [];
    if (currentUser == null) return badges;

    void checkAndAdd(List<UserBadge> milestones, double value) {
      UserBadge? earned;
      for (var badge in milestones) {
        if (value >= badge.targetHours) earned = badge;
      }
      if (earned != null) badges.add(earned);
    }

    checkAndAdd(
      BadgeDefinitions.marathonerMilestones,
      currentUser.totalHoursWatched,
    );
    checkAndAdd(
      BadgeDefinitions.obsessionMilestones,
      currentUser.maxConsecutiveHours,
    );
    checkAndAdd(BadgeDefinitions.weekendMilestones, currentUser.weekendHours);
    checkAndAdd(
      BadgeDefinitions.streakMilestones,
      currentUser.seriesStreak.toDouble(),
    );
    checkAndAdd(BadgeDefinitions.nightOwlMilestones, currentUser.nightOwlHours);
    checkAndAdd(
      BadgeDefinitions.genreMilestones,
      currentUser.uniqueGenresCount.toDouble(),
    );

    int completedCount = userSeries.where((s) => s.percentage >= 1.0).length;
    checkAndAdd(
      BadgeDefinitions.completionistMilestones,
      completedCount.toDouble(),
    );

    return badges;
  }

  static List<UserBadge> getAllUnclaimedBadges(
    User? currentUser,
    List<Series> userSeries,
  ) {
    if (currentUser == null) return [];

    final stats = {
      "Marathoner": currentUser.totalHoursWatched,
      "Pure Obsession": currentUser.maxConsecutiveHours,
      "Weekend Warrior": currentUser.weekendHours,
      "Streak": currentUser.seriesStreak.toDouble(),
      "The Perfectionist": userSeries
          .where((s) => s.percentage >= 1.0)
          .length
          .toDouble(),
      "The Night Owl": currentUser.nightOwlHours,
      "Genre Explorer": currentUser.uniqueGenresCount.toDouble(),
    };

    List<UserBadge> unlocked = [];
    for (var badge in BadgeDefinitions.allMilestones) {
      double currentVal = stats[badge.title] ?? 0.0;
      if (currentVal > 0.0 &&
          currentVal >= badge.targetHours &&
          !currentUser.claimedBadgeIds.contains(badge.id)) {
        unlocked.add(badge);
      }
    }
    return unlocked;
  }

  static Future<void> calculatePureObsession(
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

    final userDoc = _db.collection('users').doc(uid);
    final userSnap = await userDoc.get();
    double actualRecord = (userSnap.data()?['maxConsecutiveHours'] ?? 0)
        .toDouble();

    if (maxSessionHours > actualRecord) {
      await userDoc.update({'maxConsecutiveHours': maxSessionHours});
    }
  }

  static Future<void> calculateWeekendWarrior({String? userUid}) async {
    final String? uid = userUid ?? _getUid();
    if (uid == null) return;

    Map<String, double> weekendGroups = {};
    final seriesSnap = await _db
        .collection('users')
        .doc(uid)
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
              String weekendId = "${date.year}-${_getIdWeekNumber(date)}";
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
    await _db.collection('users').doc(uid).set({
      'weekendHours': maxWeekendMinutes / 60.0,
    }, SetOptions(merge: true));
  }

  static int _getIdWeekNumber(DateTime date) {
    int daysSinceJan1 = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((daysSinceJan1 + DateTime(date.year, 1, 1).weekday - 1) / 7)
            .floor() +
        1;
  }

  static Future<void> calculateNightOwl({String? userUid}) async {
    final String? uid = userUid ?? _getUid();
    if (uid == null) return;

    double totalNightMinutes = 0;
    final seriesSnap = await _db
        .collection('users')
        .doc(uid)
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
    await _db.collection('users').doc(uid).set({
      'nightOwlHours': totalNightMinutes / 60.0,
    }, SetOptions(merge: true));
  }

  static Future<List<double>> getChartData(
    ChartPeriod period, {
    String? userUid,
  }) async {
    String? uid;
    try {
      uid = userUid ?? auth.FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      uid = userUid;
    }
    if (uid == null) return [];

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
          .doc(uid)
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
              if (date.day <= dataPoints.length)
                dataPoints[date.day - 1] += hours;
            } else if (period == ChartPeriod.week) {
              final diff = now.difference(date).inDays;
              if (diff >= 0 && diff < 7) dataPoints[6 - diff] += hours;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Errore Chart Data: $e");
    }
    return dataPoints;
  }
}
