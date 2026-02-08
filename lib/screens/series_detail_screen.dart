import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:seriestime/screens/season_tile_screen.dart';
import 'package:seriestime/models/tv_show_details.dart';
import '../models/appdata.dart'; // Assicurati che il percorso sia corretto
import 'all_cast_screen.dart';

// --- CONFIGURATION ---
const String apiKey = "0cbb1da4932d8722fcddf451692e1b2e";

class SeriesDetailScreen extends StatefulWidget {
  final int seriesId;
  final String seriesName; // Utile per un titolo placeholder mentre carica

  const SeriesDetailScreen({super.key, required this.seriesId, required this.seriesName});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> with SingleTickerProviderStateMixin {
  TvShowDetails? _details;
  bool _isLoading = true;
  late TabController _tabController;
  bool _isFavorite = false;

  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 Tabs: Info e Episodes
    _fetchSeriesDetails();
    _checkTrackingStatus();
    _scrollController.addListener(() {
      // Quando superiamo una certa soglia (es. 200 pixel), mostriamo il titolo
      if (_scrollController.offset > 180 && !_showTitle) {
        setState(() => _showTitle = true);
      } else if (_scrollController.offset <= 180 && _showTitle) {
        setState(() => _showTitle = false);
      }
    });
  }

  Future<void> _checkTrackingStatus() async {
    // Ora controlliamo se è PREFERITA, non solo se esiste
    bool status = await AppData.isSeriesFavorite(widget.seriesName);
    if (mounted) {
      setState(() {
        _isFavorite = status;
      });
    }
  }

  Future<void> _handleFavoriteToggle() async {
    if (_details == null) return;

    // Aggiornamento ottimistico UI
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // Chiamiamo la nuova funzione unica passando true o false
    await AppData.setSeriesFavorite(widget.seriesName, widget.seriesId, _isFavorite);

    
  }

  Future<void> _fetchSeriesDetails() async {
    setState(() => _isLoading = true);
    try {
      // Chiamata API complessa: Dettagli + Credits (Cast) + Watch Providers (Dove guardarla)
      final url = Uri.parse(
        'https://api.themoviedb.org/3/tv/${widget.seriesId}?api_key=$apiKey&language=en-US&append_to_response=aggregate_credits,watch/providers'
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _details = TvShowDetails.fromJson(data);
        });
      } else {
        debugPrint("Error fetching details: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colori da AppData
    final primary = AppData.primaryColor;
    final accent = AppData.accentColor;
    final bg = AppData.backgroundColor;
    
    // --- CALCOLO PROPORZIONI ---
    final double screenWidth = MediaQuery.of(context).size.width;
    // Calcoliamo l'altezza per avvicinarci al 16:9 (0.56) ma lasciando spazio per il testo (0.7)
    // Su un iPhone standard sarà circa 270px invece di 400px
    final double headerHeight = screenWidth * 0.7;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (_details == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: Text("Could not load series details.")),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      // Usiamo NestedScrollView per far scrollare l'header insieme al contenuto
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: headerHeight,
              floating: false,
              pinned: true,
              backgroundColor: primary,
              elevation: 0,
              title: _showTitle 
                ? Text(
                  widget.seriesName, 
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20, 
                    fontWeight: FontWeight.bold
                  )
                ) : null,
              centerTitle: true,
              iconTheme: const IconThemeData(color: AppData.whiteColor),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(primary, accent, headerHeight, screenWidth),
              ),
            ),
             SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: accent,
                  tabs: const [
                    Tab(text: "Info"),
                    Tab(text: "Episodes"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // --- TAB 1: INFO ---
            _buildInfoTab(primary),
            // --- TAB 2: EPISODES (Placeholder) ---
            _buildEpisodesTab(),
          ],
        ),
      ),
    );
  }

  // --- HEADER WIDGET (Backdrop, Poster, Title, Button) ---
  Widget _buildHeader(Color primary, Color accent, double height, double width) {
    // Calcoliamo le dimensioni del poster in base all'altezza dell'header
    // Il poster sarà circa il 55% dell'altezza dell'header
    final double posterHeight = height * 0.55; 
    final double posterWidth = posterHeight * 0.66; // Rapporto standard poster 2:3

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Backdrop Image (Sfondo Orizzontale)
        if (_details!.backdropUrl != null)
          Image.network(
            _details!.backdropUrl!, 
            fit: BoxFit.cover, // Copre il box
            alignment: Alignment.topCenter, // Mantiene la parte alta (spesso le teste degli attori)
          )
        else
          Container(color: primary.withAlpha(77)),
        
        // 2. Gradiente Scuro (Migliorato per leggibilità su header più basso)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(51), // Leggero scuro in alto per la freccia back
                Colors.transparent,
                Colors.black.withAlpha(230), // Scuro in basso per i testi
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),

        // 3. Contenuto Header
        Positioned(
          bottom: 16, // Margine dal basso
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Poster Verticale (Con ombra per staccare dallo sfondo)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 8, offset: const Offset(0, 4))
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _details!.posterUrl != null
                      ? Image.network(_details!.posterUrl!, width: posterWidth, height: posterHeight, fit: BoxFit.cover)
                      : Container(width: posterWidth, height: posterHeight, color: Colors.grey),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Titolo, Tagline e Bottone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Titolo
                    Text(
                      _details!.name,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 20, // Leggermente ridotto per stare nel nuovo spazio
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                      ),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Tagline (se c'è)
                    if (_details!.tagline != null && _details!.tagline!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "\"${_details!.tagline}\"",
                        style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 12, fontStyle: FontStyle.italic),
                         maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Bottone "Aggiungi ai Preferiti"
                    SizedBox(
                      height: 36,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleFavoriteToggle, // Chiama la nostra funzione
                        style: ElevatedButton.styleFrom(
                          // Se è preferito cambia colore (es. grigio o bianco), altrimenti usa Accent
                          backgroundColor: _isFavorite ? AppData.accentColor : Colors.grey, 
                          foregroundColor: AppData.whiteColor,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        // Cambia icona: Stella piena se preferito, Bordo se non lo è
                        icon: Icon(
                          _isFavorite ? Icons.star : Icons.star_border, 
                          size: 18,
                          color: _isFavorite ? Colors.amber : Colors.white, // Stella gialla se attivo
                        ),
                        // Cambia testo
                        label: Text(
                          _isFavorite ? "Favorited" : "Add to Favorites", 
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppData.whiteColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  // --- INFO TAB CONTENT ---
  Widget _buildInfoTab(Color primaryTextColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ABOUT SECTION
          _buildSectionTitle("About", primaryTextColor),
          _buildInfoCard(
            children: [
              _buildInfoRow(Icons.calendar_today, "Start Date", _details!.firstAirDate ?? "N/A"),
              _buildInfoRow(Icons.tv, "Status", _details!.status),
              _buildInfoRow(Icons.layers, "Seasons", "${_details!.numberOfSeasons}"),
              _buildInfoRow(Icons.format_list_numbered, "Total Episodes", "${_details!.numberOfEpisodes}"),
              if (_details!.networks.isNotEmpty) _buildInfoRow(Icons.cell_tower, "Network", _details!.networks.join(", ")),
               if (_details!.creators.isNotEmpty) _buildInfoRow(Icons.person, "Created By", _details!.creators.join(", ")),
              _buildInfoRow(Icons.category, "Genres", _details!.genres.join(", ")),
            ],
          ),

          // 2. OVERVIEW SECTION
          _buildSectionTitle("Overview", primaryTextColor),
          _buildInfoCard(
            children: [
              Text(_details!.overview.isNotEmpty ? _details!.overview : "No overview available.", style: TextStyle(color: Colors.grey[800], height: 1.4)),
            ]
          ),

          // 3. CAST SECTION (Top Cast)
          
          

          if (_details!.cast.isNotEmpty) ... [
            _buildSectionTitle("Top Cast", primaryTextColor),
            SizedBox(
              height: 215, // Definisce l'altezza totale della striscia (Card completa)
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                // Se ci sono più di 10 attori, aggiungiamo 1 alla lunghezza per il tasto "View All"
                itemCount: _details!.cast.take(10).length + (_details!.cast.length > 10 ? 1 : 0),
                itemBuilder: (context, index) {
                  
                  // --- TASTO VIEW ALL (Ultimo elemento) ---
                  if (index == 10 || index == _details!.cast.length) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllCastScreen(
                              fullCast: _details!.cast, 
                              seriesName: _details!.name
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.only(left: 8, right: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Icons.arrow_forward, color: AppData.primaryColor, size: 20),
                            ),
                            const Text(
                              "View All",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppData.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }

                  // --- CARD ATTORE (Stile identico a AllCastScreen) ---
                  final actor = _details!.cast[index];
                  
                  return Container(
                    width: 115,
                    // Aumentiamo leggermente l'altezza totale da 210 a 220 per stare comodi con 4 righe di testo totali
                    // Ricordati di cambiare anche l'altezza del SizedBox padre a 220!
                    // height: 220, 
                    
                    margin: const EdgeInsets.only(right: 10, bottom: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppData.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // 1. FOTO (Fissa)
                        SizedBox( 
                          height: 135, 
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: actor.profileUrl != null
                                ? Image.network(actor.profileUrl!, fit: BoxFit.cover)
                                : Container(color: Colors.grey[300], child: const Icon(Icons.person, color: Colors.grey, size: 105)),
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // 2. TESTI (Ottimizzati)
                        // Nome Attore: Permettiamo 2 righe
                        Text(
                          actor.name,
                          maxLines: 2, // <--- MODIFICA: Da 1 a 2 righe
                          overflow: TextOverflow.ellipsis, 
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: AppData.primaryColor,
                            height: 1.1 // Line height stretto per risparmiare spazio
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 4),

                        // Nome Personaggio: Permettiamo 2 righe
                        Text(
                          actor.characterName,
                          maxLines: 4, 
                          overflow: TextOverflow.ellipsis, 
                          style: TextStyle(
                            fontSize: 10, 
                            color: Colors.grey[600],
                            height: 1.1
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // 4. WHERE TO WATCH & RATING (Affiancati)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Where to watch
              Expanded(
                flex: 3,
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Where to Watch", primaryTextColor),
                     _buildInfoCard(
                      children: [
                        if (_details!.watchProviders.isEmpty) const Text("Not available based on TMDB data (US region).") else
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _details!.watchProviders.map((wp) => Tooltip(
                            message: wp.providerName,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(wp.logoUrl, width: 40, height: 40),
                            ),
                          )).toList(),
                        )
                      ]
                     ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Rating
              Expanded(
                flex: 2,
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Rating", primaryTextColor),
                     _buildInfoCard(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Icon(Icons.star, color: Colors.amber[700], size: 28),
                             const SizedBox(width: 8),
                             Text(_details!.voteAverage.toStringAsFixed(1), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor)),
                          ],
                        ),
                        Center(child: Text("Based on ${_details!.voteCount} votes", style: TextStyle(color: Colors.grey[600], fontSize: 11))),
                      ]
                     ),
                  ],
                ),
              ),
            ],
          ),
          

          // 5. LAST EPISODE SECTION
          if (_details!.lastEpisode != null) ...[
            _buildSectionTitle("Last Episode Aired", primaryTextColor),
             _buildInfoCard(
              children: [
                Text("S${_details!.lastEpisode!.seasonNumber} E${_details!.lastEpisode!.episodeNumber} - \"${_details!.lastEpisode!.name}\"", style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 4),
                 Text("Aired on: ${_details!.lastEpisode!.airDate}", style: TextStyle(color: Colors.grey[700])),
              ]
             ),
          ],
           const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS FOR UI ---
  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 15.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppData.whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
         boxShadow: [BoxShadow(color: Colors.black.withAlpha(7), blurRadius: 5, offset: const Offset(0, 2))]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildEpisodesTab() {
    if (_details!.seasons.isEmpty) {
      return const Center(child: Text("No seasons information available."));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 10, bottom: 35),
      child: Column(
        children: _details!.seasons.map((season) {
          return SeasonTile(
            seriesId: widget.seriesId,
            seriesName: _details!.name,
            season: season,
          );
        }).toList(),
      ),
    );
  }
}

// Classe necessaria per far funzionare la TabBar dentro una NestedScrollView
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppData.whiteColor, // Colore sfondo della tab bar quando pinnata
      child: _tabBar,
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}