import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/user_badge.dart';

class BadgeDetailScreen extends StatelessWidget {
  final String categoryTitle;
  final List<UserBadge> milestones;
  final double currentValue;
  final String unit;

  const BadgeDetailScreen({
    super.key,
    required this.categoryTitle,
    required this.milestones,
    required this.currentValue,
    required this.unit,
  });

  String _getDetailedDescription() {
    switch (categoryTitle) {
      case "Marathoner":
        return "This mission tracks your total lifetime watch time. Every minute you spend watching an episode is converted into hours. Reach the targets to level up from a beginner to a legendary series marathoner!";
      case "Pure Obsession":
        return "Measures your longest consecutive binge-watching session. To count as a single session, episodes must be watched within 10 minutes of each other. How long can you stay glued to the screen?";
      case "Weekend Warrior":
        return "Tracks the maximum number of hours you've watched exclusively during weekends (Friday to Sunday). Perfect for those who save their favorite shows for a Saturday binge!";
      case "Streak":
        return "Counts consecutive days of activity. To maintain your streak, you must watch at least one episode every 24 hours. If you skip a day, the counter resets to 0!";
      case "The Perfectionist":
        return "Awarded based on the total number of series you have completely finished (100% progress). Quality over quantity—show your dedication to finishing what you started.";
      case "The Night Owl":
        return "Tracks hours watched during late-night hours (between midnight and 4:00 AM). While others sleep, you dive deeper into your favorite stories.";
      case "Genre Explorer":
        return "Measures your curiosity! This badge levels up as you watch series from different genres (Action, Drama, Sci-Fi, etc.). Diversify your watchlist to claim this reward.";
      default:
        return "Complete specific tasks within the app to unlock milestones and earn exclusive badges.";
    }
  }

  String _formatDisplayValue() {
    if (unit == 'S') {
      return "${currentValue.toInt()} Series";
    }

    if (unit == 'G') {
      return "${currentValue.toInt()} Genres";
    }

    if (unit == 'd') {
      int d = currentValue.toInt();
      return "${d}d";
    }

    if (unit == 'dh') {
      int d = (currentValue / 24).floor();
      int h = (currentValue % 24).floor(); 
      return "${d}d ${h}h";
    }

    if (unit == 'h') {
      if (currentValue <= 0) return "0m";
      int h = currentValue.toInt();
      int m = ((currentValue - h) * 60).round();

      if (h > 0 && m > 0) return "${h}h ${m}m";
      if (h > 0) return "${h}h";
      return "${m}m";
    }

    return "${currentValue.toStringAsFixed(1)} $unit";
  }

  @override
  Widget build(BuildContext context) {
    final List<String> claimedIds = AppData.currentUser?.claimedBadgeIds ?? [];
    final UserBadge currentBadge = milestones.lastWhere(
      (m) => claimedIds.contains(m.id),
      orElse: () => milestones.first,
    );

    bool isSpecial =
        categoryTitle == "Streak" || categoryTitle == "The Perfectionist";

    return Scaffold(
      backgroundColor: AppData.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppData.primaryColor,
        title: Text(
          categoryTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppData.whiteColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Transform.scale(
                    scale: isSpecial ? 1.8 : 1.2,
                    child: Image.asset(
                      currentBadge.imagePath,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    _formatDisplayValue(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppData.primaryColor,
                    ),
                  ),
                  
                  Text(
                    "Total Progress",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppData.accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppData.accentColor.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          color: AppData.accentColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "How it works",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppData.accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDetailedDescription(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mission Milestones",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  ...milestones.map((m) {
                    bool isUnlocked = claimedIds.contains(m.id);
                    double milestoneProgress = (currentValue / m.targetHours)
                        .clamp(0.0, 1.0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isUnlocked
                              ? AppData.primaryColor
                              : Colors.grey[300]!,
                          width: isUnlocked ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: isUnlocked ? 1.0 : 0.4,
                            child: Image.asset(
                              m.imagePath,
                              width: 50,
                              height: 50,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Level: ${m.iconLabel}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isUnlocked
                                            ? AppData.primaryColor
                                            : Colors.black54,
                                      ),
                                    ),
                                    if (isUnlocked)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppData.primaryColor,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: milestoneProgress,
                                  backgroundColor: Colors.grey[200],
                                  color: isUnlocked
                                      ? AppData.primaryColor
                                      : AppData.accentColor,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}