import 'package:cloud_firestore/cloud_firestore.dart'; // Import necessario
import 'package:flutter/material.dart';
import 'package:seriestime/models/next_episode_info.dart';
import 'package:seriestime/models/series.dart';
import 'models/appdata.dart';

class MySeriesScreen extends StatefulWidget {
  const MySeriesScreen({super.key});

  @override
  State<MySeriesScreen> createState() => _MySeriesScreenState();
}

class _MySeriesScreenState extends State<MySeriesScreen> {
  // Future per caricare i dati "Upcoming"
  late Future<Map<String, NextEpisodeInfo>> _upcomingEpisodesFuture;

  @override
  void initState() {
    super.initState();
    // Inizializziamo il future, ma verrà ricaricato quando lo stream aggiorna i dati
    _upcomingEpisodesFuture = _loadUpcomingEpisodes();
  }

  // Funzione che itera su tutte le serie utente e cerca i prossimi episodi
  Future<Map<String, NextEpisodeInfo>> _loadUpcomingEpisodes() async {
    final Map<String, NextEpisodeInfo> upcomingMap = {};
    final List<Future<void>> tasks = [];

    // Usiamo una copia locale per evitare errori di concorrenza
    final List<Series> currentList = AppData.userSeries.where((s) {
      bool isWatching = s.percentage > 0.0 && s.percentage < 1.0;
      return s.isFavorite || isWatching;
    }).toList();

    for (var series in currentList) {
      tasks.add(AppData.fetchNextEpisode(series.id).then((info) {
        if (info != null && info.daysLeft >= 0) {
          upcomingMap[series.name] = info;
        }
      }));
    }
    await Future.wait(tasks);
    return upcomingMap;
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder per aggiornamento Real-Time
    return StreamBuilder<QuerySnapshot>(
      stream: AppData.seriesStream(),
      builder: (context, snapshot) {
        
        // 1. Gestione Caricamento Iniziale
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppData.backgroundColor,
            body: Center(child: CircularProgressIndicator(color: AppData.primaryColor)),
          );
        }

        // 2. AGGIORNAMENTO DATI: Popoliamo la lista statica con i dati freschi dal DB
        AppData.userSeries = snapshot.data!.docs.map((doc) {
          final sData = doc.data() as Map<String, dynamic>;
          
          return Series(
            id: sData['id'] ?? 0, 
            name: doc.id,
            imageUrl: sData['imageUrl'] ?? "",
            percentage: (sData['percentage'] ?? 0).toDouble(),
            totalHours: (sData['totalHours'] ?? 0).toDouble(),
            episode: sData['episode'] ?? "",
            lastEpisodeTitle: sData['lastEpisodeTitle'] ?? "",
            seriesDuration: (sData['seriesDuration'] ?? 0).toDouble(),
            isFavorite: sData['isFavorite'] ?? false, 
          );
        }).toList();

        // 3. Filtriamo le liste per le Tab
        final favoriteSeries = AppData.userSeries.where((s) => s.isFavorite).toList();
        final watchingSeries = AppData.userSeries
            .where((s) => s.percentage > 0.0 && s.percentage < 1.0) 
            .toList();
        
        return DefaultTabController(
          length: 3, 
          child: Scaffold(
            backgroundColor: AppData.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppData.primaryColor,
              elevation: 0,
              title: Text(
                "My Series",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w600, 
                  color: AppData.whiteColor
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50.0), 
                child: Container(
                  color: AppData.whiteColor, 
                  child: TabBar(
                    labelColor: AppData.primaryColor, 
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppData.accentColor, 
                    tabs: const [
                      Tab(text: "Favorites"),
                      Tab(text: "Watching"),
                      Tab(text: "Upcoming"),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                _buildFavoritesTab(favoriteSeries),
                _buildWatchingTab(watchingSeries),
                _buildUpcomingTab(), 
              ],
            ),
          ),
        );
      }
    );
  }

  // --- BUILDER TAB PREFERITI (MODIFICATO: GRID VIEW) ---
  Widget _buildFavoritesTab(List<Series> favoriteSeries) {
    if (favoriteSeries.isEmpty) {
      return _buildEmptyState("No favorites yet.\nAdd series from Explore!");
    }
    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        childAspectRatio: 0.68, // <--- MODIFICA QUI (Era 0.55). 0.68 è ideale per soli poster.
        crossAxisSpacing: 12,   // Leggermente aumentato per spaziare meglio
        mainAxisSpacing: 12,
      ),
      itemCount: favoriteSeries.length,
      itemBuilder: (ctx, index) {
        return SeriesListCard(series: favoriteSeries[index]);
      },
    );
  }

  Widget _buildWatchingTab(List<Series> watchingSeries) {
    if (watchingSeries.isEmpty) { 
       return _buildEmptyState("No series in progress.\nStart watching from Explore!");
    }
    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: watchingSeries.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final series = watchingSeries[index];
        return WatchingEpisodeCard(
          imageUrl: series.imageUrl,
          // SCAMBIAMO: Titolo episodio diventa il principale, Nome serie il secondario
          mainText: series.lastEpisodeTitle.isNotEmpty ? series.lastEpisodeTitle : series.name,
          subText: series.name, 
          episodeLabel: series.episode, 
          isUpcoming: false,
        );
      },
    );
  }

  Widget _buildUpcomingTab() {
    return FutureBuilder<Map<String, NextEpisodeInfo>>(
      future: _upcomingEpisodesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppData.accentColor));
        }
        
        if (AppData.userSeries.isEmpty) {
           return _buildEmptyState("Add series to see upcoming episodes.");
        }

        final upcomingMap = snapshot.data ?? {};
        
        if (upcomingMap.isEmpty && snapshot.connectionState == ConnectionState.done) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _upcomingEpisodesFuture = _loadUpcomingEpisodes();
              });
              await _upcomingEpisodesFuture;
            },
            child: _buildEmptyState("No upcoming episodes found.")
          );
        }

        final sortedKeys = upcomingMap.keys.toList()
          ..sort((a, b) => upcomingMap[a]!.airDate.compareTo(upcomingMap[b]!.airDate));

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _upcomingEpisodesFuture = _loadUpcomingEpisodes();
            });
            await _upcomingEpisodesFuture;
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            itemCount: sortedKeys.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final seriesName = sortedKeys[index];
              final info = upcomingMap[seriesName]!;

              String imageUrl = info.stillUrl ?? "";
              if (imageUrl.isEmpty) {
                final series = AppData.userSeries.firstWhere(
                  (s) => s.name == seriesName, 
                  orElse: () => AppData.userSeries.isNotEmpty ? AppData.userSeries[0] : Series(id:0, name: "", imageUrl: "", percentage: 0, totalHours: 0, episode: "")
                );
                imageUrl = series.imageUrl;
              }

              String dateFormatted = "${info.airDate.year}-${info.airDate.month}-${info.airDate.day}";

              return WatchingEpisodeCard(
                imageUrl: imageUrl,
                // SCAMBIAMO: Titolo episodio principale
                mainText: info.name,
                subText: seriesName,
                episodeLabel: info.episodeLabel,
                // Passiamo la data extra
                extraInfo: dateFormatted, 
                isUpcoming: true,
                daysLeft: info.daysLeft,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- WIDGETS UI ---
// -----------------------------------------------------------------------------

// MODIFICATA: Card Verticale per Favorites
// MODIFICA: Card SOLO POSTER per Favorites
class SeriesListCard extends StatelessWidget {
  final Series series;
  const SeriesListCard({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black, // Sfondo scuro nel caso l'immagine non carichi
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppData.accentColor, width: 2), // Bordo Accent
        boxShadow: [
           BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 3))
        ]
      ),
      // ClipRRect ora arrotonda TUTTI gli angoli, non solo quelli in alto
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10), // Radius interno (12 - 2 di bordo)
        child: Image.network(
          series.imageUrl,
          fit: BoxFit.cover, // L'immagine riempie tutto lo spazio
          errorBuilder: (c, e, s) => Container(
            color: Colors.grey[800], 
            child: const Center(child: Icon(Icons.movie, color: Colors.white54))
          ),
        ),
      ),
    );
  }
}

// MODIFICATA: Card Orizzontale per Watching e Upcoming
class WatchingEpisodeCard extends StatelessWidget {
  final String imageUrl;
  final String mainText; // Ora generico (Episode Title)
  final String subText;  // Ora generico (Series Name)
  final String episodeLabel;
  final String? extraInfo;
  final bool isUpcoming;
  final int? daysLeft;

  const WatchingEpisodeCard({
    super.key,
    required this.imageUrl,
    required this.mainText, // Updated param name
    required this.subText,  // Updated param name
    required this.episodeLabel,
    this.extraInfo,
    this.isUpcoming = false,
    this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppData.accentColor, width: 2), 
        boxShadow: [
           BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        children: [
          // 1. Immagine
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
            child: Image.network(
              imageUrl,
              width: 70, 
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(width: 70, color: Colors.grey[800]),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Info Testuali RIORGANIZZATE
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITOLO EPISODIO (Principale)
                Text(
                  mainText, 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold, 
                    color: AppData.primaryColor, // Colore Primario
                  ),
                ),
                
                // NOME SERIE (Secondario)
                Text(
                  subText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.w500, 
                    color: Colors.black87 // Nero/Grigio scuro
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // RIGA INFO (Stagione/Episodio + Data)
                Row(
                  children: [
                    Text(
                      episodeLabel, // "S1 E5"
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600, 
                        color: AppData.accentColor
                      ),
                    ),
                    if (extraInfo != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.circle, size: 4, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        extraInfo!, // Data (es. 12/10/2025)
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),

          // 3. Conto alla rovescia o Icona Play
          if (isUpcoming && daysLeft != null)
            Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$daysLeft",
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: AppData.primaryColor
                    ),
                  ),
                  const Text(
                    "days", // Semplificato per spazio
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            )
          else if (!isUpcoming)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.play_circle_fill, 
                color: AppData.accentColor.withAlpha(200),
                size: 32
              ),
            )
        ],
      ),
    );
  }
}