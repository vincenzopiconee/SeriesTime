import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_screen.dart';
import 'series_progress_screen.dart';

class Series {
  final String name;
  final String imageUrl;
  final double percentage;
  final String time;

  Series({
    required this.name,
    required this.imageUrl,
    required this.percentage,
    required this.time,
  });
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<List<Series>> fetchSeriesData() async {
    final List<String> showNames = [
      "Peaky Blinders",
      "Lost",
      "Lucifer",
      "Game of Thrones",
      "Senna",
      "Squid Game",
      "Money Heist",
      "Stranger Things",
    ];

    final List<double> percentages = [
      1.0,
      0.15,
      0.65,
      0.88,
      0.50,
      1.0,
      0.75,
      0.42,
    ];
    final List<String> hours = [
      "36h",
      "14h",
      "54h",
      "62h",
      "3h",
      "24h",
      "29h",
      "15h",
    ];

    List<Series> loadedSeries = [];

    for (int i = 0; i < showNames.length; i++) {
      try {
        final response = await http.get(
          Uri.parse(
            'https://api.tvmaze.com/singlesearch/shows?q=${showNames[i]}',
          ),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          loadedSeries.add(
            Series(
              name: data['name'],
              imageUrl: data['image'] != null ? data['image']['medium'] : '',
              percentage: percentages[i],
              time: hours[i],
            ),
          );
        }
      } catch (e) {
        debugPrint("Errore caricamento ${showNames[i]}: $e");
      }
    }
    return loadedSeries;
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildWatchTimeCard(),
                  const SizedBox(height: 20),
                  _buildFakeChart(),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Titolo Griglia
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SERIES WATCH TIME",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 15),

            FutureBuilder<List<Series>>(
              future: fetchSeriesData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B261A)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("Impossibile caricare le serie.");
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (context, index) {
                    return _buildSeriesCard(snapshot.data![index]);
                  },
                );
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

  Widget _buildWatchTimeCard() {
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
      child: const Column(
        children: [
          Text(
            "TOTAL WATCH TIME:",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261A),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "10d  3h  2m",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Image.network(
                series.imageUrl,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image),
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      series.time,
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
}
