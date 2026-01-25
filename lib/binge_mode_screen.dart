import 'package:flutter/material.dart';
import 'models/appdata.dart';
import 'models/userbadge.dart';

class BingeModeScreen extends StatelessWidget {
  const BingeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppData.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = AppData.currentUser!;
    final timeData = AppData.getTotalWatchTimeSplit();

    // populating Data and the progress for each achievement
    final UserBadge targetMarathoner = AppData.getMarathonerTarget();
    double progressMarathoner =
        user.totalHoursWatched / targetMarathoner.targetHours;
    if (progressMarathoner > 1.0) progressMarathoner = 1.0;
    bool isMarathonerFinished = user.totalHoursWatched >= 2400; // 100 days
    final UserBadge targetObsession = AppData.getObsessionTarget(
      user.maxConsecutiveHours,
    );
    double progressObsession =
        user.maxConsecutiveHours / targetObsession.targetHours;
    if (progressObsession > 1.0) progressObsession = 1.0;
    bool isObsessionFinished = user.maxConsecutiveHours >= 20;
    final UserBadge targetWeekend = AppData.getWeekendTarget(user.weekendHours);
    double progressWeekend = user.weekendHours / targetWeekend.targetHours;
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
            // CARD MARATHONER
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

            // CARD PURE OBSESSION
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

            // CARD WEEKEND WARRIOR
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
  }

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
            // expanded is needed to occupy all the space of the Row (or Column) Widget
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
                  // stack permits to overlap one or more widget
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
