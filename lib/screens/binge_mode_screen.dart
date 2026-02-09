import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_data.dart';
import '../models/user_badge.dart';
import '../models/user.dart';
import '../models/series.dart';
import 'badge_detail_screen.dart';

class BingeModeScreen extends StatelessWidget {
  const BingeModeScreen({super.key});

  String _formatDuration(double totalHours) {
    if (totalHours <= 0) return "0m";
    int h = totalHours.toInt();
    int m = ((totalHours - h) * 60).round();

    if (h > 0 && m > 0) return "${h}h ${m}m";
    if (h > 0) return "${h}h";
    return "${m}m";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: AppData.userStream(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: AppData.seriesStream(),
          builder: (context, seriesSnapshot) {
            if (!userSnapshot.hasData || !seriesSnapshot.hasData) {
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: AppData.primaryColor,
                  elevation: 0,
                  centerTitle: true,
                  title: const Text(
                    "Binge Mode",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            AppData.currentUser = User(
              name: userData['name'] ?? "User",
              totalHoursWatched: (userData['totalHoursWatched'] ?? 0).toDouble(),
              maxConsecutiveHours: (userData['maxConsecutiveHours'] ?? 0).toDouble(),
              weekendHours: (userData['weekendHours'] ?? 0).toDouble(),
              nightOwlHours: (userData['nightOwlHours'] ?? 0).toDouble(),
              uniqueGenresCount: (userData['uniqueGenresCount'] ?? 0).toInt(),
              claimedBadgeIds: List<String>.from(
                userData['claimedBadgeIds'] ?? [],
              ),
              seriesStreak: userData['seriesStreak'] ?? 0,
            );

            AppData.userSeries = seriesSnapshot.data!.docs.map((doc) {
              final sData = doc.data() as Map<String, dynamic>;
              return Series(
                id: sData['id'] ?? 0,
                name: doc.id,
                imageUrl: sData['imageUrl'] ?? "",
                percentage: (sData['percentage'] ?? 0).toDouble(),
                totalHours: (sData['totalHours'] ?? 0).toDouble(),
                episode: sData['episode'] ?? "",
              );
            }).toList();

            final user = AppData.currentUser!;
            final double realTotalHours = AppData.getTotalWatchTimeHours();
            final timeData = AppData.getTotalWatchTimeSplit();

            final UserBadge targetMarathoner = AppData.getMarathonerTarget();
            double progressMarathoner =
                realTotalHours / targetMarathoner.targetHours;
            if (progressMarathoner > 1.0) progressMarathoner = 1.0;

            final UserBadge targetObsession = AppData.getObsessionTarget(
              user.maxConsecutiveHours,
            );
            double progressObsession =
                user.maxConsecutiveHours / targetObsession.targetHours;
            if (progressObsession > 1.0) progressObsession = 1.0;

            final UserBadge targetWeekend = AppData.getWeekendTarget(
              user.weekendHours,
            );
            double progressWeekend =
                user.weekendHours / targetWeekend.targetHours;
            if (progressWeekend > 1.0) progressWeekend = 1.0;
            final UserBadge targetStreak = AppData.getStreakTarget(
              user.seriesStreak.toDouble(),
            );
            double progressStreak =
                user.seriesStreak / targetStreak.targetHours;
            if (progressStreak > 1.0) progressStreak = 1.0;

            int completedCount = AppData.userSeries
                .where((s) => s.percentage >= 1.0)
                .length;
            final UserBadge targetComp = AppData.getCompletionistTarget(
              completedCount.toDouble(),
            );
            double progressComp = completedCount / targetComp.targetHours;
            if (progressComp > 1.0) progressComp = 1.0;

            final UserBadge targetNightOwl = AppData.getNightOwlTarget(
              user.nightOwlHours,
            );
            double progressNightOwl =
                user.nightOwlHours / targetNightOwl.targetHours;
            if (progressNightOwl > 1.0) progressNightOwl = 1.0;
            final UserBadge targetGenre = AppData.getGenreTarget(
              user.uniqueGenresCount,
            );
            double progressGenre =
                user.uniqueGenresCount / targetGenre.targetHours;
            if (progressGenre > 1.0) progressGenre = 1.0;

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                backgroundColor: AppData.backgroundColor,
                appBar: AppBar(
                  backgroundColor: AppData.primaryColor,
                  elevation: 0,
                  centerTitle: true,
                  title: const Text(
                    "Binge Mode",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48.0),
                    child: Container(
                      color: Colors.white,
                      child: const TabBar(
                        labelColor: AppData.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppData.accentColor,
                        tabs: [
                          Tab(text: "Quests"),
                          Tab(text: "Completed"),
                        ],
                      ),
                    ),
                  ),
                ),
                body: TabBarView(
                  children: [
                    _buildQuestsTab(
                      user,
                      realTotalHours,
                      timeData,
                      completedCount,
                      context,
                    ),
                    _buildCompletedTab(user, realTotalHours, completedCount),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildCompletedTab(User user, double totalHours, int completedCount) {
    final allPossibleBadges = [
      ...AppData.marathonerMilestones,
      ...AppData.obsessionMilestones,
      ...AppData.weekendMilestones,
      ...AppData.streakMilestones,
      ...AppData.completionistMilestones,
      ...AppData.nightOwlMilestones,
      ...AppData.genreMilestones,
    ];

    final List<UserBadge> allClaimed = allPossibleBadges
        .where((badge) => user.claimedBadgeIds.contains(badge.id))
        .toList();

    if (allClaimed.isEmpty) {
      return const Center(
        child: Text(
          "No badges claimed yet.\nComplete a quest and click CLAIM!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    allClaimed.sort((a, b) => a.title.compareTo(b.title));

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: allClaimed.length,
      itemBuilder: (context, index) {
        final badge = allClaimed[index];
        List<UserBadge> categoryMilestones = [];
        double currentProgressValue = 0;
        String unit = "h";


        if (badge.title == "Marathoner") {
          categoryMilestones = AppData.marathonerMilestones;
          currentProgressValue = totalHours;
          unit = "dh"; 
        } else if (badge.title == "Pure Obsession") {
          categoryMilestones = AppData.obsessionMilestones;
          currentProgressValue = user.maxConsecutiveHours;
          unit = "h";
        } else if (badge.title == "Weekend Warrior") {
          categoryMilestones = AppData.weekendMilestones;
          currentProgressValue = user.weekendHours;
          unit = "h";
        } else if (badge.title == "Streak") {
          categoryMilestones = AppData.streakMilestones;
          currentProgressValue = user.seriesStreak.toDouble();
          unit = "d"; 
        } else if (badge.title == "The Perfectionist") {
          categoryMilestones = AppData.completionistMilestones;
          currentProgressValue = completedCount.toDouble();
          unit = "S";
        } else if (badge.title == "The Night Owl") {
          categoryMilestones = AppData.nightOwlMilestones;
          currentProgressValue = user.nightOwlHours;
          unit = "h";
        } else if (badge.title == "Genre Explorer") {
          categoryMilestones = AppData.genreMilestones;
          currentProgressValue = user.uniqueGenresCount.toDouble();
          unit = "G";
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BadgeDetailScreen(
                  categoryTitle: badge.title,
                  milestones: categoryMilestones,
                  currentValue: currentProgressValue,
                  unit: unit,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _buildAchievementCard(
              title: badge.title,
              description: "Level Completed!",
              progressText: "CLAIMED",
              progressValue: 1.0,
              badge: badge,
              canClaim: false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestsTab(
    User user,
    double realTotalHours,
    Map<String, int> timeData,
    int completedCount,
    BuildContext context,
  ) {
    UserBadge findCurrentTarget(
      List<UserBadge> milestones,
      double currentVal,
    ) {
      return milestones.firstWhere(
        (b) => !user.claimedBadgeIds.contains(b.id),
        orElse: () => milestones.last,
      );
    }

    final targetM = findCurrentTarget(
      AppData.marathonerMilestones,
      realTotalHours,
    );
    final targetO = findCurrentTarget(
      AppData.obsessionMilestones,
      user.maxConsecutiveHours,
    );
    final targetW = findCurrentTarget(
      AppData.weekendMilestones,
      user.weekendHours,
    );
    final targetS = findCurrentTarget(
      AppData.streakMilestones,
      user.seriesStreak.toDouble(),
    );
    final targetC = findCurrentTarget(
      AppData.completionistMilestones,
      completedCount.toDouble(),
    );
    final targetNO = findCurrentTarget(
      AppData.nightOwlMilestones,
      user.nightOwlHours,
    );
    final targetG = findCurrentTarget(
      AppData.genreMilestones,
      user.uniqueGenresCount.toDouble(),
    );

    Widget questItem(
      UserBadge target,
      double currentProgress,
      String progressText,
      List<UserBadge> categoryMilestones,
      String unit,
    ) {
      if (user.claimedBadgeIds.contains(target.id)) {
        return const SizedBox.shrink();
      }

      bool canClaim = currentProgress >= target.targetHours;
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BadgeDetailScreen(
                categoryTitle: target.title,
                milestones: categoryMilestones,
                currentValue: currentProgress,
                unit: unit,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: _buildAchievementCard(
            title: target.title,
            description: "Reach ${target.iconLabel} to complete this level.",
            progressText: canClaim ? "READY TO CLAIM" : progressText,
            progressValue: (currentProgress / target.targetHours).clamp(
              0.0,
              1.0,
            ),
            badge: target,
            canClaim: canClaim,
            onClaim: () => AppData.claimBadge(target.id),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        children: [
          questItem(
            targetM,
            realTotalHours,
            "${timeData["days"]}d ${timeData["hours"]}h / ${targetM.iconLabel}",
            AppData.marathonerMilestones,
            "dh",
          ),
          questItem(
            targetO,
            user.maxConsecutiveHours,
            "${_formatDuration(user.maxConsecutiveHours)} / ${targetO.iconLabel}",
            AppData.obsessionMilestones,
            "h",
          ),
          questItem(
            targetW,
            user.weekendHours,
            "${_formatDuration(user.weekendHours)} / ${targetW.iconLabel}",
            AppData.weekendMilestones,
            "h",
          ),
          questItem(
            targetS,
            user.seriesStreak.toDouble(),
            "${user.seriesStreak}d 0h / ${targetS.iconLabel}",
            AppData.streakMilestones,
            "d",
          ),
          questItem(
            targetC,
            completedCount.toDouble(),
            "$completedCount / ${targetC.iconLabel}",
            AppData.completionistMilestones,
            "S",
          ),
          questItem(
            targetNO,
            user.nightOwlHours,
            "${_formatDuration(user.nightOwlHours)} / ${targetNO.iconLabel}",
            AppData.nightOwlMilestones,
            "h",
          ),
          questItem(
            targetG,
            user.uniqueGenresCount.toDouble(),
            "${user.uniqueGenresCount} / ${targetG.iconLabel}",
            AppData.genreMilestones,
            "G",
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required String title,
    required String description,
    required String progressText,
    required double progressValue,
    required UserBadge badge,
    bool canClaim = false,
    VoidCallback? onClaim,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppData.accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppData.backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppData.accentColor, width: 1.5),
                ),
                child: Center(
                  child: Transform.scale(
                    scale: (title == "Streak" || title == "The Perfectionist")
                        ? 1.7
                        : 1.0,
                    child: Image.asset(
                      badge.imagePath,
                      height: 60,
                      width: 60,
                      fit: BoxFit.contain,
                    ),
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
                            color: Colors.grey[400],
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
          if (canClaim) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppData.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "CLAIM REWARD",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}