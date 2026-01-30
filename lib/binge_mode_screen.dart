import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'models/appdata.dart';
import 'models/userbadge.dart';
import 'models/user.dart';
import 'models/series.dart';

class BingeModeScreen extends StatelessWidget {
  const BingeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo sia i dati utente che le serie per calcolare le ore reali
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(auth.FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(auth.FirebaseAuth.instance.currentUser?.uid)
              .collection('series')
              .snapshots(),
          builder: (context, seriesSnapshot) {
            if (!userSnapshot.hasData || !seriesSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 1. SINCRONIZZAZIONE DATI FIRESTORE -> APPDATA
            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            AppData.currentUser = User(
              name: userData['name'] ?? "User",
              totalHoursWatched: (userData['totalHoursWatched'] ?? 0)
                  .toDouble(),
              maxConsecutiveHours: userData['maxConsecutiveHours'] ?? 0,
              weekendHours: userData['weekendHours'] ?? 0,
              notification: userData['notification'] ?? true,
            );

            AppData.userSeries = seriesSnapshot.data!.docs.map((doc) {
              final sData = doc.data() as Map<String, dynamic>;
              return Series(
                name: doc.id,
                imageUrl: sData['imageUrl'] ?? "",
                percentage: (sData['percentage'] ?? 0).toDouble(),
                totalHours: sData['totalHours'] ?? 0,
                episode: sData['episode'] ?? "",
              );
            }).toList();

            // 2. CALCOLO VALORI REALI (Basato sulle serie aggiornate)
            final user = AppData.currentUser!;
            // Ricalcoliamo il tempo totale basato sulle percentuali attuali nel DB
            final double realTotalHours = AppData.getTotalWatchTimeHours();
            final timeData = AppData.getTotalWatchTimeSplit();

            // Calcolo Marathoner Target
            final UserBadge targetMarathoner = AppData.getMarathonerTarget();
            double progressMarathoner =
                realTotalHours / targetMarathoner.targetHours;
            if (progressMarathoner > 1.0) progressMarathoner = 1.0;
            bool isMarathonerFinished = realTotalHours >= 2400;

            // Calcolo Obsession Target
            final UserBadge targetObsession = AppData.getObsessionTarget(
              user.maxConsecutiveHours,
            );
            double progressObsession =
                user.maxConsecutiveHours / targetObsession.targetHours;
            if (progressObsession > 1.0) progressObsession = 1.0;
            bool isObsessionFinished = user.maxConsecutiveHours >= 20;

            // Calcolo Weekend Target
            final UserBadge targetWeekend = AppData.getWeekendTarget(
              user.weekendHours,
            );
            double progressWeekend =
                user.weekendHours / targetWeekend.targetHours;
            if (progressWeekend > 1.0) progressWeekend = 1.0;
            bool isWeekendFinished = user.weekendHours >= 48;

            return Scaffold(
              backgroundColor: AppData.backgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: const Text(
                  "BINGE MODE",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 27,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 30,
                  bottom: 120,
                ),
                child: Column(
                  children: [
                    _buildAchievementCard(
                      title: targetMarathoner.title,
                      description: isMarathonerFinished
                          ? "You are a true legend! Max level reached."
                          : "Reach ${targetMarathoner.iconLabel.replaceAll('G', '')} days of total watch time.",
                      progressText: isMarathonerFinished
                          ? "COMPLETED"
                          : "${timeData["days"]}d ${timeData["hours"]}h / ${targetMarathoner.iconLabel.replaceAll('G', 'd 00h')}",
                      progressValue: progressMarathoner,
                      badge: targetMarathoner,
                    ),
                    const SizedBox(height: 20),
                    _buildAchievementCard(
                      title: targetObsession.title,
                      description: isObsessionFinished
                          ? "Your obsession has no limits. Max level reached."
                          : "Watch the same TV series for ${targetObsession.targetHours.toInt()} consecutive hours.",
                      progressText: isObsessionFinished
                          ? "COMPLETED"
                          : "${user.maxConsecutiveHours}h / ${targetObsession.iconLabel}",
                      progressValue: progressObsession,
                      badge: targetObsession,
                    ),
                    const SizedBox(height: 20),
                    _buildAchievementCard(
                      title: targetWeekend.title,
                      description: isWeekendFinished
                          ? "The ultimate weekend warrior! Max level reached."
                          : "Watch ${targetWeekend.targetHours.toInt()} hours of content within 3 days.",
                      progressText: isWeekendFinished
                          ? "COMPLETED"
                          : "${user.weekendHours}h / ${targetWeekend.iconLabel}",
                      progressValue: progressWeekend,
                      badge: targetWeekend,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget _buildAchievementCard rimane lo stesso del tuo codice originale...
  Widget _buildAchievementCard({
    required String title,
    required String description,
    required String progressText,
    required double progressValue,
    required UserBadge badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppData.accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppData.backgroundColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppData.accentColor, width: 1.5),
            ),
            child: Center(
              child: Image.asset(
                badge.imagePath,
                height: 70,
                width: 70,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 15),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 21,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progressValue,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppData.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      progressText,
                      style: const TextStyle(
                        color: AppData.whiteColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
