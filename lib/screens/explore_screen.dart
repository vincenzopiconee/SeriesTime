import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:seriestime/models/tv_show.dart';
import '../models/appdata.dart';
import 'series_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TvShow> _shows = [];
  bool _isLoading = false;
  
  int? _selectedGenreId;
  
  Timer? _debounce;

  final List<Genre> _availableGenres = [
    Genre(id: 10759, name: "Action & Adventure"),
    Genre(id: 18, name: "Drama"),
    Genre(id: 35, name: "Comedy"),
    Genre(id: 10765, name: "Sci-Fi & Fantasy"),
    Genre(id: 9648, name: "Mystery"),
    Genre(id: 80, name: "Crime"),
    Genre(id: 16, name: "Animation"),
  ];

  @override
  void initState() {
    super.initState();
    _fetchShows();
  }

  Future<void> _fetchShows([String? query]) async {
    final String searchText = query ?? _searchController.text;
    
    setState(() => _isLoading = true);

    try {
      Uri url;

      if (searchText.trim().isEmpty) {
        String baseUrl = 'https://api.themoviedb.org/3/discover/tv?api_key=${AppData.tmdbApiKey}&language=en-US&sort_by=popularity.desc&include_adult=false&include_null_first_air_dates=false';
        if (_selectedGenreId != null) {
          baseUrl += '&with_genres=$_selectedGenreId';
        }
        url = Uri.parse(baseUrl);
      } else {
        url = Uri.parse(
          'https://api.themoviedb.org/3/search/tv?api_key=${AppData.tmdbApiKey}&query=$searchText&language=en-US&include_adult=false'
        );
      }
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        
        List<TvShow> fetchedShows = results.map((json) => TvShow.fromJson(json)).toList();

        if (searchText.trim().isNotEmpty && _selectedGenreId != null) {
          fetchedShows = fetchedShows.where((show) {
            return show.genreIds.contains(_selectedGenreId);
          }).toList();
        }

        setState(() {
          _shows = fetchedShows;
        });
      } else {
        debugPrint("TMDB Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchShows(query);
    });
  }

  void _onGenreTap(int genreId) {
    setState(() {
      if (_selectedGenreId == genreId) {
        _selectedGenreId = null;
      } else {
        _selectedGenreId = genreId;
      }
    });
    _fetchShows();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppData.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppData.primaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Explore",
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.w600, 
            color: AppData.whiteColor
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppData.whiteColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300), 
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: "Search TV Series...",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _fetchShows(""); 
                        },
                      )
                    : null,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _availableGenres.length,
              itemBuilder: (context, index) {
                final genre = _availableGenres[index];
                final isSelected = _selectedGenreId == genre.id;

                return GestureDetector(
                  onTap: () => _onGenreTap(genre.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppData.accentColor: Colors.grey[400], 
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        genre.name,
                        style: const TextStyle(
                          color: AppData.whiteColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _searchController.text.isEmpty 
                    ? (_selectedGenreId == null ? "Trending Now" : "Popular in ${_availableGenres.firstWhere((g) => g.id == _selectedGenreId).name}")
                    : "Search Results",
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: AppData.primaryColor
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shows.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tv_off, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text(
                              "No series found matching criteria",
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 5, bottom: 90),
                        itemCount: _shows.length,
                        itemBuilder: (context, index) {
                          return _buildShowCard(_shows[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowCard(TvShow show) {
    const double cardHeight = 180;
    const double imgWidth = cardHeight * 0.68; 
    

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeriesDetailScreen(seriesId: show.id, seriesName: show.name),
          ),
        );
      },
      child: Container(
        height: cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: AppData.whiteColor, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppData.accentColor, width: 2.0), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: show.posterUrl != null
                  ? Image.network(
                      show.posterUrl!,
                      width: imgWidth,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        width: imgWidth,
                        height: double.infinity,
                        color: Colors.grey,
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(
                      width: imgWidth,
                      height: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.tv, size: 40, color: Colors.grey),
                    ),
            ),


            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            show.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppData.primaryColor, 
                              height: 1.1,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (show.voteAverage > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.amber[800]),
                                const SizedBox(width: 4),
                                Text(
                                  show.voteAverage.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        if (show.country != null) ...[
                          Text(
                            show.country!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppData.primaryColor, 
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text("•", style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 8),
                        ],
                        if (show.year.isNotEmpty)
                          Text(
                            show.year,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppData.primaryColor, 
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if (show.overview.isNotEmpty)
                      Expanded(
                        child: Text(
                          show.overview,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800], 
                            height: 1.2,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),

                    const SizedBox(height: 8),

                    Text(
                      show.genres.isNotEmpty ? show.genres.join(", ") : "No genres",
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppData.primaryColor, 
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}