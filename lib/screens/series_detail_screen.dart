import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:seriestime/widgets/season_tile.dart';
import 'package:seriestime/models/tv_show_details.dart';
import '../models/appdata.dart'; 
import 'all_cast_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:seriestime/models/user.dart';

const String apiKey = "0cbb1da4932d8722fcddf451692e1b2e";

class SeriesDetailScreen extends StatefulWidget {
  final int seriesId;
  final String seriesName; 

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
    _tabController = TabController(length: 2, vsync: this); 
    _fetchSeriesDetails();
    _checkTrackingStatus();
    _scrollController.addListener(() {
      if (_scrollController.offset > 180 && !_showTitle) {
        setState(() => _showTitle = true);
      } else if (_scrollController.offset <= 180 && _showTitle) {
        setState(() => _showTitle = false);
      }
    });
  }

  Future<void> _checkTrackingStatus() async {
    bool status = await AppData.isSeriesFavorite(widget.seriesName);
    if (mounted) {
      setState(() {
        _isFavorite = status;
      });
    }
  }

  Future<void> _handleFavoriteToggle() async {
    if (_details == null) return;
    setState(() {
      _isFavorite = !_isFavorite;
    });
    await AppData.setSeriesFavorite(widget.seriesName, widget.seriesId, _isFavorite);
  }

  Future<void> _fetchSeriesDetails() async {
    setState(() => _isLoading = true);
    try {
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
    final primary = AppData.primaryColor;
    final accent = AppData.accentColor;
    final bg = AppData.backgroundColor;
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final double headerHeight = screenWidth * 0.7;

    return StreamBuilder<DocumentSnapshot>(
      stream: AppData.userStream(),
      builder: (context, userSnapshot) {
        
        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          AppData.currentUser = User(
            name: userData['name'] ?? "User",
            totalHoursWatched: (userData['totalHoursWatched'] ?? 0).toDouble(),
            maxConsecutiveHours: (userData['maxConsecutiveHours'] ?? 0).toDouble(),
            weekendHours: (userData['weekendHours'] ?? 0).toDouble(),
            nightOwlHours: (userData['nightOwlHours'] ?? 0).toDouble(),
            uniqueGenresCount: (userData['uniqueGenresCount'] ?? 0).toInt(),
            seriesStreak: userData['seriesStreak'] ?? 0,
            claimedBadgeIds: List<String>.from(userData['claimedBadgeIds'] ?? []),
            photoUrl: userData['photoUrl'] ?? auth.FirebaseAuth.instance.currentUser?.photoURL,
          );
        }

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
                _buildInfoTab(primary),
                _buildEpisodesTab(),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader(Color primary, Color accent, double height, double width) {
    final double posterHeight = height * 0.55; 
    final double posterWidth = posterHeight * 0.66; 

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_details!.backdropUrl != null)
          Image.network(
            _details!.backdropUrl!, 
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          )
        else
          Container(color: primary.withAlpha(77)),
        
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(51),
                Colors.transparent,
                Colors.black.withAlpha(230),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),

        Positioned(
          bottom: 16, 
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _details!.name,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                      ),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (_details!.tagline != null && _details!.tagline!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "\"${_details!.tagline}\"",
                        style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 12, fontStyle: FontStyle.italic),
                         maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      height: 36,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleFavoriteToggle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFavorite ? AppData.accentColor : Colors.grey, 
                          foregroundColor: AppData.whiteColor,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        icon: Icon(
                          _isFavorite ? Icons.star : Icons.star_border, 
                          size: 18,
                          color: _isFavorite ? Colors.amber : Colors.white,
                        ),
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

  Widget _buildInfoTab(Color primaryTextColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          _buildSectionTitle("Overview", primaryTextColor),
          _buildInfoCard(
            children: [
              Text(_details!.overview.isNotEmpty ? _details!.overview : "No overview available.", style: TextStyle(color: Colors.grey[800], height: 1.4)),
            ]
          ),

          if (_details!.cast.isNotEmpty) ... [
            _buildSectionTitle("Top Cast", primaryTextColor),
            SizedBox(
              height: 215, 
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _details!.cast.take(10).length + (_details!.cast.length > 10 ? 1 : 0),
                itemBuilder: (context, index) {
                  
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

                  final actor = _details!.cast[index];
                  
                  return Container(
                    width: 115,
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
                        
                        Text(
                          actor.name,
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis, 
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: AppData.primaryColor,
                            height: 1.1 
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 4),

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

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
      color: AppData.whiteColor, 
      child: _tabBar,
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}