import 'package:flutter/material.dart';

import 'settings_screen.dart';
import 'series_progress_screen.dart';
import '../models/appdata.dart';
import '../models/series.dart';
import '../models/userbadge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import 'binge_mode_screen.dart';
import 'all_badges_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ChartPeriod _selectedPeriod = ChartPeriod.year;
  final Map<ChartPeriod, List<double>> _cachedChartData = {};
  Future<List<double>>? _initialLoadFuture;

  @override
  void initState() {
    super.initState();
    // Carichiamo inizialmente solo i dati dell'anno
    _initialLoadFuture = AppData.getChartData(ChartPeriod.year).then((data) {
      _cachedChartData[ChartPeriod.year] = data;
      // Una volta caricato l'anno, avviamo il caricamento degli altri in background
      _loadRemainingData();
      return data;
    });
  }

  void _loadRemainingData() async {
    try {
      // Carichiamo i dati mancanti
      final results = await Future.wait([
        AppData.getChartData(ChartPeriod.month),
        AppData.getChartData(ChartPeriod.week),
      ]);

      // Verifichiamo che il widget sia ancora "vivo" prima di chiamare setState
      if (mounted) {
        setState(() {
          _cachedChartData[ChartPeriod.month] = results[0];
          _cachedChartData[ChartPeriod.week] = results[1];
        });
      }
    } catch (e) {
      debugPrint("Errore nel caricamento dati background: $e");
    }
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
                // AGGIUNTO: Mostriamo la AppBar anche durante il caricamento
                appBar: AppBar(
                  backgroundColor: AppData.primaryColor,
                  elevation: 0,
                  title: const Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppData.whiteColor,
                    ),
                  ),
                  centerTitle: true,
                ),
                body: const Center(
                  child: CircularProgressIndicator(color: AppData.primaryColor),
                ),
              );
            }

            // Controllo di sicurezza: se i dati sono nulli (es. logout in corso), mostra caricamento
            if (userSnapshot.data!.data() == null) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppData.primaryColor),
                ),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;

            AppData.userSeries = seriesSnapshot.data!.docs.map((doc) {
              final sData = doc.data() as Map<String, dynamic>;
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

                title: const Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppData.whiteColor,
                  ),
                ),
                centerTitle: true,
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
                              color: AppData.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 21,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildWatchTimeCard(days, remainingHours, minutes),
                          const SizedBox(height: 20),
                          _buildActivityChart(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- SEZIONE MY BADGES (SINCRONIZZATA CON BINGE MODE) ---
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
                      child: Builder(
                        builder: (context) {
                          // Recuperiamo gli ID riscattati direttamente dai dati correnti dello snapshot
                          final List<String> claimedIds = List<String>.from(
                            userData['claimedBadgeIds'] ?? [],
                          );

                          // Creiamo la lista di TUTTI i singoli badge sbloccati (come in Binge Mode)
                          final List<UserBadge> allClaimed =
                              [
                                    ...AppData.marathonerMilestones,
                                    ...AppData.obsessionMilestones,
                                    ...AppData.weekendMilestones,
                                    ...AppData.streakMilestones,
                                    ...AppData.completionistMilestones,
                                    ...AppData.nightOwlMilestones,
                                    ...AppData.genreMilestones,
                                  ]
                                  .where(
                                    (badge) => claimedIds.contains(badge.id),
                                  )
                                  .toList();

                          // Se la lista filtrata è vuota, mostriamo il messaggio
                          if (allClaimed.isEmpty) {
                            return _buildEmptyBadgesMessage();
                          }

                          // Altrimenti mostriamo la lista orizzontale con la freccia View All
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            // Limite a 3 badge + 1 posto per la freccia se ce ne sono di più
                            itemCount: allClaimed.length > 4
                                ? 5
                                : allClaimed.length,
                            itemBuilder: (context, index) {
                              // Se abbiamo più di 3 badge e siamo all'indice 3, mostriamo la freccia
                              if (allClaimed.length > 4 && index == 4) {
                                return _buildViewAllBadgeButton();
                              }
                              return _buildBadgeItem(allClaimed[index]);
                            },
                          );
                        },
                      ),
                    ),
                    // NOTA: Verifica che non ci sia più l'ElevatedButton "View More Badges" qui sotto
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
    return const Center(child: Text("Keep watching to unlock badges!"));
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
              fontSize: 21,
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
          // PARTE SINISTRA: Immagine
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
          // PARTE DESTRA: Percentuale e Ore (Ripristinata)
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        color: Colors.grey,
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

  Widget _buildActivityChart() {
    // Ora containsKey funzionerà senza errori perché la mappa non è null
    if (_cachedChartData.containsKey(_selectedPeriod)) {
      return _drawChartContent(_cachedChartData[_selectedPeriod]!);
    }

    return FutureBuilder<List<double>>(
      future: _initialLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: AppData.primaryColor),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Se i dati arrivano ma non sono ancora in cache per qualche motivo, li aggiungiamo
          if (!_cachedChartData.containsKey(ChartPeriod.year)) {
            _cachedChartData[ChartPeriod.year] = snapshot.data!;
          }
          return _drawChartContent(snapshot.data!);
        }

        return const SizedBox(
          height: 200,
          child: Center(child: Text("Loading activity data...")),
        );
      },
    );
  }

  Widget _drawChartContent(List<double> chartData) {
    // 1. Definiamo maxVal ALL'INIZIO della funzione
    final double maxVal = chartData.isEmpty
        ? 10.0
        : chartData.reduce((a, b) => a > b ? a : b).clamp(5.0, double.infinity);

    String subTitle = "";
    if (_selectedPeriod == ChartPeriod.week)
      subTitle = "Activity in the current week";
    else if (_selectedPeriod == ChartPeriod.month)
      subTitle = "Activity in current Month";
    else
      subTitle = "Activity in current Year";

    List<String> labels = [];
    if (_selectedPeriod == ChartPeriod.year) {
      labels = [
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
        "Dec",
      ];
    } else if (_selectedPeriod == ChartPeriod.week) {
      DateTime now = DateTime.now();
      labels = List.generate(7, (index) {
        DateTime day = now.subtract(Duration(days: 6 - index));
        return ["M", "T", "W", "T", "F", "S", "S"][day.weekday - 1];
      });
    } else {
      labels = List.generate(chartData.length, (i) => (i + 1).toString());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Watch Activity",
                    style: TextStyle(
                      color: AppData.accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subTitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _periodButton("W", ChartPeriod.week),
                  _periodButton("M", ChartPeriod.month),
                  _periodButton("Y", ChartPeriod.year),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // SCALA Y CORRETTA (qui maxVal è riconosciuto)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatChartValue(maxVal),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatChartValue(maxVal / 2),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "0h",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        4,
                        (index) => Divider(
                          height: 1,
                          color: Colors.grey[100],
                          thickness: 1,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(chartData.length, (index) {
                        double barHeight = (chartData[index] / maxVal) * 130;
                        bool showLabel =
                            _selectedPeriod != ChartPeriod.month ||
                            (index + 1) % 5 == 0 ||
                            index == 0;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: _selectedPeriod == ChartPeriod.month
                                  ? 4
                                  : 12,
                              height: barHeight.clamp(3.0, 130.0),
                              decoration: BoxDecoration(
                                color: chartData[index] > 0
                                    ? AppData.primaryColor
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 12,
                              child: showLabel
                                  ? Text(
                                      labels[index],
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllBadgeButton() {
    return GestureDetector(
      onTap: () {
        // 1. Ricreiamo la lista completa di tutti i badge sbloccati (come fatto nel build)
        final List<UserBadge> allClaimed =
            [
                  ...AppData.marathonerMilestones,
                  ...AppData.obsessionMilestones,
                  ...AppData.weekendMilestones,
                  ...AppData.streakMilestones,
                  ...AppData.completionistMilestones,
                  ...AppData.nightOwlMilestones,
                  ...AppData.genreMilestones,
                ]
                .where(
                  (badge) =>
                      AppData.currentUser!.claimedBadgeIds.contains(badge.id),
                )
                .toList();

        // 2. Navighiamo alla nuova pagina AllBadgesScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllBadgesScreen()),
        );
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(left: 10, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.arrow_forward_ios,
              color: AppData.primaryColor,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              "View All",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppData.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodButton(String label, ChartPeriod period) {
    bool isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppData.primaryColor : Colors.grey[500],
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
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
          Transform.scale(
            scale: badge.title == "Streak" || badge.title == "The Perfectionist"
                ? 1.7
                : 1.0,
            child: Image.asset(
              badge.imagePath,
              height: 60,
              width: 60,
              fit: BoxFit.contain,
            ),
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

  String formatChartValue(double totalHours) {
    if (totalHours <= 0) return "0h";
    int d = (totalHours / 24).floor();
    int h = (totalHours % 24).round();

    if (d > 0) {
      return "${d}d ${h}h";
    }
    return "${h}h";
  }
}
