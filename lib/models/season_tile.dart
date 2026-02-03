
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:seriestime/models/appdata.dart';
import 'package:seriestime/models/tv_show_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import necessario
import 'package:firebase_auth/firebase_auth.dart';

const String apiKey = "0cbb1da4932d8722fcddf451692e1b2e"; 

class SeasonTile extends StatefulWidget {
  final int seriesId;
  final String seriesName;
  final Season season;

  const SeasonTile({super.key, required this.seriesId, required this.seriesName, required this.season});

  @override
  State<SeasonTile> createState() => _SeasonTileState();
}

class _SeasonTileState extends State<SeasonTile> {
  List<Episode>? _episodes;
  bool _isLoading = false;
  
  // Set locale per simulare i "Visti". In futuro questo arriverà da Firebase.
  //final Set<int> _watchedEpisodeIds = {}; 

  // Funzione per scaricare gli episodi di QUESTA specifica stagione
  Future<void> _fetchEpisodes() async {
    if (_episodes != null) return; 

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        'https://api.themoviedb.org/3/tv/${widget.seriesId}/season/${widget.season.seasonNumber}?api_key=$apiKey&language=en-US'
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['episodes'] != null) {
          setState(() {
            _episodes = (data['episodes'] as List).map((e) => Episode.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching episodes: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Stream<DocumentSnapshot> _getEpisodeStream(int episodeNum) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('series')
        .doc(widget.seriesName) // Usa il nome della serie come ID documento
        .collection('seasons')
        .doc('Season ${widget.season.seasonNumber}')
        .collection('episodes')
        .doc('Episode $episodeNum')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppData.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Theme(
        // Rimuoviamo le linee divisorie di default dell'ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          textColor: AppData.primaryColor,
          collapsedTextColor: AppData.primaryColor,
          iconColor: AppData.primaryColor,
          collapsedIconColor: Colors.grey,
          title: Text(
            widget.season.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            "${widget.season.episodeCount} Episodes",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          onExpansionChanged: (expanded) {
            if (expanded) {
              _fetchEpisodes();
            }
          },
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator(color: AppData.primaryColor)),
              )
            else if (_episodes == null || _episodes!.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No episodes found."),
              )
            else
              ..._episodes!.map((episode) => _buildEpisodeCard(episode)),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeCard(Episode episode) {
    String dateLabel = "";
    bool isFuture = false;

    if (episode.airDate != null && episode.airDate!.isNotEmpty) {
      dateLabel = " • ${episode.airDate}";
      try {
        DateTime airDate = DateTime.parse(episode.airDate!);
        DateTime now = DateTime.now();
        // Normalizziamo 'oggi' a mezzanotte per confrontare solo i giorni
        DateTime today = DateTime(now.year, now.month, now.day);
        
        // Se la data è DOPO oggi, è nel futuro.
        if (airDate.isAfter(today)) {
          isFuture = true;
        }
      } catch (e) {
        debugPrint("Date parsing error: $e");
      }
    }

    // Avvolgiamo tutto nello StreamBuilder per ascoltare Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: _getEpisodeStream(episode.episodeNumber),
      builder: (context, snapshot) {
        
        bool isWatched = false;
        // Se il documento esiste e ha il campo 'watched' a true
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          isWatched = data['watched'] ?? false;
        }

        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              // 1. Immagine
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: episode.stillUrl != null
                    ? Image.network(episode.stillUrl!, width: 80, height: 45, fit: BoxFit.cover)
                    : Container(width: 80, height: 45, color: Colors.grey[300], child: const Icon(Icons.image, size: 20, color: Colors.grey)),
              ),
              const SizedBox(width: 12),
              
              // 2. Info Testuali
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Ep ${episode.episodeNumber}",
                          style: const TextStyle(fontSize: 11, color: AppData.primaryColor, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          dateLabel,
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      episode.name,
                      style: const TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600, 
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),

              // 3. LOGICA TOGGLE
              if (isFuture) 
                // CASO A: EPISODIO FUTURO -> Nessun bottone o icona lucchetto/orologio
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.access_time, size: 20, color: Colors.grey),
                )
              else
              // CASO B: EPISODIO USCITO -> Bottone funzionante
                InkWell(
                  onTap: () {                  
                    AppData.toggleEpisodeWatched(
                      seriesName: widget.seriesName,
                      seriesId: widget.seriesId,
                      seasonNum: widget.season.seasonNumber,
                      episodeNum: episode.episodeNumber,
                      episodeTitle: episode.name,
                      isWatched: !isWatched, // Passiamo il valore opposto a quello attuale
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWatched ? AppData.accentColor : Colors.grey[200],
                      border: Border.all(
                        color: isWatched ? AppData.accentColor : Colors.grey.shade400,
                      )
                    ),
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: isWatched ? Colors.white : Colors.grey[500],
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }
}