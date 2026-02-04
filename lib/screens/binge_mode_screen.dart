import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appdata.dart';
import '../models/userbadge.dart';
import '../models/user.dart';
import '../models/series.dart';

class BingeModeScreen extends StatelessWidget {
  const BingeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //streamBuilder handles the stream of data, stream is the source (firebase),
    // the builder is the function triggered when the DB is changed
    // ( then context is the context of the app and the snapshot is an object
    // which contain the state of the app (snapsht.data, snapshot.error) )
    return StreamBuilder<DocumentSnapshot>(
      stream: AppData.userStream(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          // nested streambuilder to collect also the series
          stream: AppData.seriesStream(),
          builder: (context, seriesSnapshot) {
            if (!userSnapshot.hasData || !seriesSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            //saves the date in the snaphot as a Map
            AppData.currentUser = User(
              name: userData['name'] ?? "User",
              totalHoursWatched: (userData['totalHoursWatched'] ?? 0)
                  .toDouble(),
              maxConsecutiveHours: (userData['maxConsecutiveHours'] ?? 0)
                  .toDouble(),
              weekendHours: (userData['weekendHours'] ?? 0).toDouble(),
              nightOwlHours: (userData['nightOwlHours'] ?? 0).toDouble(),
              uniqueGenresCount: (userData['uniqueGenresCount'] ?? 0).toInt(),
              seriesStreak: userData['seriesStreak'] ?? 0,
              notification: userData['notification'] ?? true,
            );

            AppData.userSeries = seriesSnapshot.data!.docs.map((doc) {
              final sData = doc.data() as Map<String, dynamic>;
              return Series(
                id: sData['id'] ?? 0,
                name: doc.id,
                imageUrl: sData['imageUrl'] ?? "",
                percentage: (sData['percentage'] ?? 0).toDouble(),
                totalHours: sData['totalHours'] ?? 0,
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
            bool isMarathonerFinished = realTotalHours >= 2400;

            final UserBadge targetObsession = AppData.getObsessionTarget(
              user.maxConsecutiveHours,
            );
            double progressObsession =
                user.maxConsecutiveHours / targetObsession.targetHours;
            if (progressObsession > 1.0) progressObsession = 1.0;
            bool isObsessionFinished = user.maxConsecutiveHours >= 20;

            final UserBadge targetWeekend = AppData.getWeekendTarget(
              user.weekendHours,
            );
            double progressWeekend =
                user.weekendHours / targetWeekend.targetHours;
            if (progressWeekend > 1.0) progressWeekend = 1.0;
            bool isWeekendFinished = user.weekendHours >= 48;
            final UserBadge targetStreak = AppData.getStreakTarget(
              user.seriesStreak.toDouble(),
            );
            double progressStreak =
                user.seriesStreak / targetStreak.targetHours;
            if (progressStreak > 1.0) progressStreak = 1.0;
            bool isStreakFinished = user.seriesStreak >= 365;

            int completedCount = AppData.userSeries
                .where((s) => s.percentage >= 1.0)
                .length;
            final UserBadge targetComp = AppData.getCompletionistTarget(
              completedCount.toDouble(),
            );
            double progressComp = completedCount / targetComp.targetHours;
            if (progressComp > 1.0) progressComp = 1.0;
            bool isCompFinished = completedCount >= 50;

            final UserBadge targetNightOwl = AppData.getNightOwlTarget(
              user.nightOwlHours,
            );
            double progressNightOwl =
                user.nightOwlHours / targetNightOwl.targetHours;
            if (progressNightOwl > 1.0) progressNightOwl = 1.0;
            bool isNightOwlFinished = user.nightOwlHours >= 50;
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
                      letterSpacing: 1.2,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(50.0),
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
    final List<UserBadge> allCompleted = [
      ...AppData.marathonerMilestones.where((b) => totalHours >= b.targetHours),
      ...AppData.obsessionMilestones.where(
        (b) => user.maxConsecutiveHours >= b.targetHours,
      ),
      ...AppData.weekendMilestones.where(
        (b) => user.weekendHours >= b.targetHours,
      ),
      ...AppData.streakMilestones.where(
        (b) => user.seriesStreak >= b.targetHours,
      ),
      ...AppData.completionistMilestones.where(
        (b) => completedCount >= b.targetHours,
      ),
      ...AppData.nightOwlMilestones.where(
        (b) => user.nightOwlHours >= b.targetHours,
      ),
      ...AppData.genreMilestones.where(
        (b) => user.uniqueGenresCount >= b.targetHours,
      ),
    ];

    if (allCompleted.isEmpty) {
      return const Center(
        child: Text(
          "No badges earned yet. Keep watching!",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      itemCount: allCompleted.length,
      itemBuilder: (context, index) {
        final badge = allCompleted[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: _buildAchievementCard(
            title: badge.title,
            description: "Level Completed!",
            progressText: "Completed",
            progressValue: 1.0,
            badge: badge,
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
  ) {
    final UserBadge targetMarathoner = AppData.getMarathonerTarget();
    final UserBadge targetObsession = AppData.getObsessionTarget(
      user.maxConsecutiveHours,
    );
    final UserBadge targetWeekend = AppData.getWeekendTarget(user.weekendHours);
    final UserBadge targetStreak = AppData.getStreakTarget(
      user.seriesStreak.toDouble(),
    );
    final UserBadge targetComp = AppData.getCompletionistTarget(
      completedCount.toDouble(),
    );
    final UserBadge targetNightOwl = AppData.getNightOwlTarget(
      user.nightOwlHours,
    );
    final UserBadge targetGenre = AppData.getGenreTarget(
      user.uniqueGenresCount,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      child: Column(
        children: [
          _buildAchievementCard(
            title: targetMarathoner.title,
            description:
                "Reach ${targetMarathoner.iconLabel} of total watch time.",
            progressText:
                "${timeData["days"]}d ${timeData["hours"]}h / ${targetMarathoner.iconLabel.replaceAll('G', 'd')}",
            progressValue: (realTotalHours / targetMarathoner.targetHours)
                .clamp(0.0, 1.0),
            badge: targetMarathoner,
          ),
          const SizedBox(height: 15),
          _buildAchievementCard(
            title: targetObsession.title,
            description:
                "Watch for ${targetObsession.targetHours.toInt()} consecutive hours.",
            progressText:
                "${user.maxConsecutiveHours.toStringAsFixed(1)}h / ${targetObsession.iconLabel}",
            progressValue:
                (user.maxConsecutiveHours / targetObsession.targetHours).clamp(
                  0.0,
                  1.0,
                ),
            badge: targetObsession,
          ),
          const SizedBox(height: 15),
          _buildAchievementCard(
            title: targetWeekend.title,
            description:
                "Watch ${targetWeekend.targetHours.toInt()}h during the weekend.",
            progressText:
                "${user.weekendHours.toStringAsFixed(1)}h / ${targetWeekend.iconLabel}",
            progressValue: (user.weekendHours / targetWeekend.targetHours)
                .clamp(0.0, 1.0),
            badge: targetWeekend,
          ),
          const SizedBox(height: 15),
          _buildAchievementCard(
            title: "Daily Fan",
            description:
                "Watch at least one episode for ${targetStreak.targetHours.toInt()} days.",
            progressText: "${user.seriesStreak} / ${targetStreak.iconLabel}",
            progressValue: (user.seriesStreak / targetStreak.targetHours).clamp(
              0.0,
              1.0,
            ),
            badge: targetStreak,
          ),
          const SizedBox(height: 15),
          _buildAchievementCard(
            title: "The Perfectionist",
            description:
                "Complete ${targetComp.targetHours.toInt()} series to 100%.",
            progressText:
                "$completedCount / ${targetComp.iconLabel.replaceAll('S', '')}",
            progressValue: (completedCount / targetComp.targetHours).clamp(
              0.0,
              1.0,
            ),
            badge: targetComp,
          ),
          const SizedBox(height: 15),
          _buildAchievementCard(
            title: targetNightOwl.title,
            description:
                "Watch ${targetNightOwl.targetHours.toInt()}h between 00:00 and 04:00.",
            progressText:
                "${user.nightOwlHours.toStringAsFixed(1)}h / ${targetNightOwl.iconLabel}",
            progressValue: (user.nightOwlHours / targetNightOwl.targetHours)
                .clamp(0.0, 1.0),
            badge: targetNightOwl,
          ),
          const SizedBox(height: 15),
          _buildAchievementCard(
            title: targetGenre.title,
            description:
                "Explore ${targetGenre.targetHours.toInt()} different genres.",
            progressText:
                "${user.uniqueGenresCount} / ${targetGenre.iconLabel}",
            progressValue: (user.uniqueGenresCount / targetGenre.targetHours)
                .clamp(0.0, 1.0),
            badge: targetGenre,
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
      child: Row(
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
              child: Image.asset(
                badge.imagePath,
                height: 60,
                width: 60,
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
