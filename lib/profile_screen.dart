import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_screen.dart';
import 'series_progress_screen.dart';
import 'models/appdata.dart';
import 'models/series.dart';
import 'models/userbadge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timeData = AppData.getTotalWatchTimeSplit();
    final int days = timeData["days"]!;
    final int remainingHours = timeData["hours"]!;
    final int minutes = timeData["minutes"]!;
    final List<Series> filteredSeries = AppData.userSeries
        .where((s) => s.percentage < 1.0)
        .toList();
    filteredSeries.sort((a, b) => b.percentage.compareTo(a.percentage));
    final List<Series> displaySeries = filteredSeries.take(6).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFF4A5568),
              child: Icon(Icons.person, size: 55, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              "FRANCESCO\nLO MONACO",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B261A),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2D3748), width: 2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  const Text(
                    "STATISTICS",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                "MY BADGES",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 105,
              child: AppData.userBadges.isEmpty
                  ? Center(
                      child: Text(
                        "You don't have any badges yet.\nKeep watching to unlock them!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppData.userBadges.length,
                      itemBuilder: (context, index) {
                        return _buildBadgeItem(AppData.userBadges[index]);
                      },
                    ),
            ),

            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SERIES WATCH TIME",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 15),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displaySeries.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                return _buildSeriesCard(displaySeries[index]);
              },
            ),

            const SizedBox(height: 5),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SeriesProgressScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3748),
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
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchTimeCard(int d, int h, int m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "TOTAL WATCH TIME:",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261A),
              letterSpacing: 1.2,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2D3748), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF2D3748), width: 1.5),
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
                        color: const Color(0xFF8B261A),
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
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      series.timeLabel,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "WATCH TIME ACTIVITY\nTHROUGH TIME",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8B261A),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
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
                        padding: const EdgeInsets.symmetric(horizontal: 5),
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
                                    color: const Color(0xFF8B261A),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D3748), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.iconLabel,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Image.asset(
            badge.imagePath,
            height: 45,
            width: 45,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 6),
          Text(
            badge.title.toUpperCase(),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
