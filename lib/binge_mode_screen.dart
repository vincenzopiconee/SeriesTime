import 'package:flutter/material.dart';
import 'models/appdata.dart';
import 'models/userbadge.dart';

class BingeModeScreen extends StatelessWidget {
  const BingeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserBadge targetMarathoner = AppData.getMarathonerTarget();
    final double totalHours = AppData.getTotalWatchTimeHours();
    final timeData = AppData.getTotalWatchTimeSplit();

    double progressMarathoner = totalHours / targetMarathoner.targetHours;
    if (progressMarathoner > 1.0) progressMarathoner = 1.0;

    bool isMarathonerFinished = totalHours >= 2400; // 100 giorni

    int currentObsessionHours = 8;
    final UserBadge targetObsession = AppData.getObsessionTarget(
      currentObsessionHours,
    );
    double progressObsession =
        currentObsessionHours / targetObsession.targetHours;
    if (progressObsession > 1.0) progressObsession = 1.0;

    bool isObsessionFinished = currentObsessionHours >= 20;

    int currentWeekendHours = 11;
    final UserBadge targetWeekend = AppData.getWeekendTarget(
      currentWeekendHours,
    );
    double progressWeekend = currentWeekendHours / targetWeekend.targetHours;
    if (progressWeekend > 1.0) progressWeekend = 1.0;

    bool isWeekendFinished = currentWeekendHours >= 48;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F0EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "BINGE MODE",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
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
                  : "${currentObsessionHours}h / ${targetObsession.iconLabel}",
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
                  : "${currentWeekendHours}h / ${targetWeekend.iconLabel}",
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
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF2D3748), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F0EB),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF2D3748), width: 1.5),
            ),
            child: Center(
              child: Image.asset(
                badge.imagePath,
                height: 80,
                width: 80,
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
                      height: 24,
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
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B261A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      progressText,
                      style: const TextStyle(
                        color: Colors.white,
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
