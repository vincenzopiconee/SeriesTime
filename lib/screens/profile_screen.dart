import 'package:flutter/material.dart';

import 'settings_screen.dart';
import 'series_progress_screen.dart';
import '../models/appdata.dart';
import '../models/series.dart';
import '../models/userbadge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: AppData.userStream(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: AppData.seriesStream(),
          builder: (context, seriesSnapshot) {
            if (!userSnapshot.hasData || !seriesSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;

            //double computedGlobalHours = 0;

            AppData.userSeries = seriesSnapshot.data!.docs.map((doc) {
              final sData = doc.data() as Map<String, dynamic>;

              AppData.syncSeriesTotalHours(doc.id);

              return Series(
                id: sData['id'] ?? 0,
                name: doc.id,
                imageUrl: sData['imageUrl'] ?? "",
                percentage: (sData['percentage'] ?? 0).toDouble(),
                totalHours: (sData['totalHours'] ?? 0).toDouble(),
                episode: sData['episode'] ?? "",
                seriesDuration: (sData['seriesDuration'] ?? 0).toDouble(),
                isFavorite: sData['isFavorite'] ?? false,
              );
            }).toList();

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
              photoUrl:
                  userData['photoUrl'] ??
                  auth.FirebaseAuth.instance.currentUser?.photoURL,
            );

            final timeData = AppData.getTotalWatchTimeSplit();
            final int days = timeData["days"]!;
            final int remainingHours = timeData["hours"]!;
            final int minutes = timeData["minutes"]!;

            AppData.generateUserBadges();

            final List<Series> filteredSeries = AppData.userSeries
                .where((s) => s.percentage < 1.0 && s.percentage > 0.0)
                .toList();
            filteredSeries.sort((a, b) => b.percentage.compareTo(a.percentage));
            final List<Series> displaySeries = filteredSeries.take(6).toList();

            final currentUser = AppData.currentUser!;

            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppData.primaryColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppData.whiteColor,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppData.whiteColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: AppData.avatarColor,
                      backgroundImage: currentUser.photoUrl != null
                          ? NetworkImage(currentUser.photoUrl!)
                          : null,
                      child: currentUser.photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 55,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentUser.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppData.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 25),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppData.whiteColor,
                        border: Border.all(
                          color: AppData.accentColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Statistics Overview",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildWatchTimeCard(days, remainingHours, minutes),
                          const SizedBox(height: 20),
                          _buildFakeChart(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "My Badges",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    SizedBox(
                      height: 115,
                      child: AppData.userBadges.isEmpty
                          ? _buildEmptyBadgesMessage()
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: AppData.userBadges.length,
                              itemBuilder: (context, index) {
                                return _buildBadgeItem(
                                  AppData.userBadges[index],
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 30),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Series Progress",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    displaySeries.isEmpty
                        ? const Text("No series in progress.")
                        : GridView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displaySeries.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                  childAspectRatio: 1.3,
                                ),
                            itemBuilder: (context, index) {
                              return _buildSeriesCard(displaySeries[index]);
                            },
                          ),

                    const SizedBox(height: 15),

                    displaySeries.isEmpty
                        ? const SizedBox(height: 1)
                        : ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SeriesProgressScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppData.accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              "View More",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyBadgesMessage() {
    return Center(child: Text("Keep watching to unlock badges!"));
  }

  Widget _buildWatchTimeCard(int d, int h, int m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        color: AppData.whiteColor,
        border: Border.all(color: AppData.accentColor, width: 2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Text(
            "Total Watch Time",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppData.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${d}d  ${h}h  ${m}m",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesCard(Series series) {
    String formattedTime = formatHours(series.totalHours);
    return Container(
      decoration: BoxDecoration(
        color: AppData.whiteColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppData.accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 8,
            offset: const Offset(3, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppData.accentColor, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.network(
                  series.imageUrl,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      size: 24,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        value: series.percentage,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey[200],
                        color: AppData.primaryColor,
                      ),
                    ),
                    Text(
                      "${(series.percentage * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 15, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
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

  Widget _buildFakeChart() {
    final List<double> chartData = [
      27,
      35,
      25,
      23,
      9,
      35,
      33,
      3,
      2,
      12,
      19,
      19,
    ];
    final List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dic",
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppData.accentColor, width: 2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Text(
            "Whatch Time Activity",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8B261A),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i in [40, 30, 20, 10])
                      Text(
                        "$i",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          5,
                          (index) => const Divider(
                            height: 1,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(chartData.length, (index) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 10,
                                  height: chartData[index] * 2.5,
                                  decoration: BoxDecoration(
                                    color: AppData.primaryColor,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  months[index],
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(UserBadge badge) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: AppData.whiteColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D3748), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 4),
          Image.asset(
            badge.imagePath,
            height: 65,
            width: 65,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String formatHours(double totalHours) {
    if (totalHours <= 0) return "0m";
    int h = totalHours.toInt();
    int m = ((totalHours - h) * 60).round();

    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }
}
