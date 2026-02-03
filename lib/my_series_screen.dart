import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import 'package:seriestime/models/next_episode_info.dart';
import 'package:seriestime/models/series.dart';
import 'models/appdata.dart';
import 'series_detail_screen.dart'; 

class MySeriesScreen extends StatefulWidget {
  const MySeriesScreen({super.key});

  @override
  State<MySeriesScreen> createState() => _MySeriesScreenState();
}

class _MySeriesScreenState extends State<MySeriesScreen> {
  late Future<Map<String, NextEpisodeInfo>> _upcomingEpisodesFuture;

  @override
  void initState() {
    super.initState();
    _upcomingEpisodesFuture = _loadUpcomingEpisodes();
  }

  Future<Map<String, NextEpisodeInfo>> _loadUpcomingEpisodes() async {
    final Map<String, NextEpisodeInfo> upcomingMap = {};
    final List<Future<void>> tasks = [];

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
    return StreamBuilder<QuerySnapshot>(
      stream: AppData.seriesStream(),
      builder: (context, snapshot) {
        
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppData.backgroundColor,
            body: Center(child: CircularProgressIndicator(color: AppData.primaryColor)),
          );
        }

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
            completed: sData['completed'] ?? false,
            nextEpisodeAirDate: sData['nextEpisodeAirDate'],
          );
        }).toList();

        final favoriteSeries = AppData.userSeries.where((s) => s.isFavorite).toList();
        final watchingSeries = AppData.userSeries
            .where((s) => s.percentage > 0.0 && s.percentage < 1.0 && !s.completed) 
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

  Widget _buildFavoritesTab(List<Series> favoriteSeries) {
    if (favoriteSeries.isEmpty) {
      return _buildEmptyState("No favorites yet.\nAdd series from Explore!");
    }
    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        childAspectRatio: 0.68, 
        crossAxisSpacing: 12,  
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
        
        // --- LOGICA PARSING EPISODIO ---
        int sNum = 1;
        int eNum = 1;
        try {
          final parts = series.episode.split(' '); 
          if (parts.length >= 2) {
            String sStr = parts[0].replaceAll(RegExp(r'[^0-9]'), ''); 
            String eStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
            sNum = int.tryParse(sStr) ?? 1;
            eNum = int.tryParse(eStr) ?? 1;
          }
        } catch (e) {
          debugPrint("Errore parsing episodio: $e");
        }

        bool isFuture = false;
        if (series.nextEpisodeAirDate != null) {
          try {
            DateTime airDate = DateTime.parse(series.nextEpisodeAirDate!);
            DateTime now = DateTime.now();
            DateTime today = DateTime(now.year, now.month, now.day);
            if (airDate.isAfter(today)) {
              isFuture = true;
            }
          } catch(e) { /* ignore */ }
        }

        return WatchingEpisodeCard(
          key: ValueKey(series.episode), // Importante: forza il rebuild se cambia episodio
          imageUrl: series.imageUrl,
          mainText: series.lastEpisodeTitle.isNotEmpty ? series.lastEpisodeTitle : series.name,
          subText: series.name, 
          episodeLabel: series.episode, 
          isUpcoming: false,
          onCheckTap: isFuture ? null : () { // Se futuro -> null, altrimenti funzione
            AppData.toggleEpisodeWatched(
              seriesName: series.name,
              seriesId: series.id,
              seasonNum: sNum,
              episodeNum: eNum,
              episodeTitle: series.lastEpisodeTitle, 
              isWatched: true, 
            );
          },
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
                mainText: info.name,
                subText: seriesName,
                episodeLabel: info.episodeLabel,
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

class SeriesListCard extends StatelessWidget {
  final Series series;
  const SeriesListCard({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeriesDetailScreen(
              seriesId: series.id,
              seriesName: series.name,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppData.accentColor, width: 2), 
          boxShadow: [
             BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 3))
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10), 
          child: Image.network(
            series.imageUrl,
            fit: BoxFit.cover, 
            errorBuilder: (c, e, s) => Container(
              color: Colors.grey[800], 
              child: const Center(child: Icon(Icons.movie, color: Colors.white54))
            ),
          ),
        ),
      ),
    );
  }
}

// --- MODIFICA: Ora è STATEFUL per gestire l'animazione del check ---
class WatchingEpisodeCard extends StatefulWidget {
  final String imageUrl;
  final String mainText; 
  final String subText;  
  final String episodeLabel;
  final String? extraInfo;
  final bool isUpcoming;
  final int? daysLeft;
  final VoidCallback? onCheckTap; 

  const WatchingEpisodeCard({
    super.key,
    required this.imageUrl,
    required this.mainText, 
    required this.subText,  
    required this.episodeLabel,
    this.extraInfo,
    this.isUpcoming = false,
    this.daysLeft,
    this.onCheckTap,
  });

  @override
  State<WatchingEpisodeCard> createState() => _WatchingEpisodeCardState();
}

class _WatchingEpisodeCardState extends State<WatchingEpisodeCard> {
  // Stato locale per l'animazione
  bool _isChecking = false;

  void _handleCheck() async {
    // 1. Evita doppi click
    if (_isChecking) return;

    // 2. Avvia animazione (cambia colore)
    setState(() {
      _isChecking = true;
    });

    // 3. Esegui la logica del database (passata dal parent)
    if (widget.onCheckTap != null) {
      widget.onCheckTap!();
    }
    
    // 4. Aspetta 1 secondo
    await Future.delayed(const Duration(seconds: 1));
    
    // 5. Reset opzionale se il widget viene riutilizzato, 
    // anche se solitamente la lista si ricostruisce con nuovi dati.
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

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
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
            child: Image.network(
              widget.imageUrl,
              width: 70, 
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(width: 70, color: Colors.grey[800]),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mainText, 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold, 
                    color: AppData.primaryColor, 
                  ),
                ),
                Text(
                  widget.subText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.w500, 
                    color: Colors.black87 
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.episodeLabel, 
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600, 
                        color: AppData.accentColor
                      ),
                    ),
                    if (widget.extraInfo != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.circle, size: 4, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        widget.extraInfo!, 
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),

          if (widget.isUpcoming && widget.daysLeft != null)
            Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${widget.daysLeft}",
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: AppData.primaryColor
                    ),
                  ),
                  const Text(
                    "days", 
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            )
          else if (!widget.isUpcoming)
            if (widget.onCheckTap == null) 
                // Se la funzione è null (significa episodio futuro in Watching Tab), nascondi tutto o metti un'icona di attesa
                const Padding(
                  padding: EdgeInsets.only(right: 24), // Spazio vuoto o icona
                  child: Icon(Icons.access_time, color: Colors.grey, size: 20),
                )
            else
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: _handleCheck, // Chiama la nostra funzione locale
                  borderRadius: BorderRadius.circular(30),
                  // Usiamo AnimatedContainer per un cambio colore fluido
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36, 
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Se _isChecking è true (cliccato) -> Accent, altrimenti -> Grigio chiaro (come richiesto)
                      color: _isChecking ? AppData.accentColor : Colors.grey[300], 
                      border: Border.all(
                        // Bordo cambia colore o rimane grigio? Qui li metto coerenti con lo sfondo
                        color: _isChecking ? AppData.accentColor : Colors.grey, 
                        width: 2
                      )
                    ),
                    child: Icon(
                      Icons.check, 
                      // Icona diventa bianca su sfondo colorato
                      color: _isChecking ? Colors.white : Colors.grey, 
                      size: 20
                    ),
                  ),
                ),
              )
        ],
      ),
    );
  }
}