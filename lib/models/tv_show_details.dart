

// ==========================================
// --- DETAILED DATA MODELS ---
// ==========================================

class TvShowDetails {
  final int id;
  final String name;
  final String? posterUrl;
  final String? backdropUrl;
  final String? tagline;
  final String overview;
  final double voteAverage;
  final int voteCount;
  final String? firstAirDate;
  final String status;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final List<String> genres;
  final List<String> networks;
  final List<String> creators;
  final List<Actor> cast;
  final List<WatchProvider> watchProviders;
  final LastEpisodeInfo? lastEpisode;
  final List<Season> seasons; // <--- NUOVO CAMPO

  TvShowDetails({
    required this.id, required this.name, required this.seasons, this.posterUrl, this.backdropUrl, this.tagline,
    required this.overview, required this.voteAverage, required this.voteCount, this.firstAirDate,
    required this.status, required this.numberOfSeasons, required this.numberOfEpisodes,
    required this.genres, required this.networks, required this.creators, required this.cast,
    required this.watchProviders, this.lastEpisode,
  });

  factory TvShowDetails.fromJson(Map<String, dynamic> json) {
    String? posterPath = json['poster_path'];
    String? backdropPath = json['backdrop_path'];

    var genresList = (json['genres'] as List?)?.map((g) => g['name'].toString()).toList() ?? [];
    var networksList = (json['networks'] as List?)?.map((n) => n['name'].toString()).toList() ?? [];
    var creatorsList = (json['created_by'] as List?)?.map((c) => c['name'].toString()).toList() ?? [];

    var seasonsList = <Season>[];
    if (json['seasons'] != null) {
      seasonsList = (json['seasons'] as List)
          .map((s) => Season.fromJson(s))
          .where((s) => s.seasonNumber > 0) // Escludiamo la stagione 0 (Specials) se vuoi, o tienila
          .toList();
    }

    // Parsing Cast (prendiamo i primi 10)
    List<Actor> castList = [];
    
    if (json['aggregate_credits'] != null && json['aggregate_credits']['cast'] != null) {
      castList = (json['aggregate_credits']['cast'] as List)
          .map((c) {
            String charName = "Unknown";
            
            // LOGICA RUOLI MULTIPLI
            if (c['roles'] != null && (c['roles'] as List).isNotEmpty) {
              final roles = c['roles'] as List;
              
              // 1. Prendiamo il primo nome (il principale)
              charName = roles[0]['character']; 

              // 2. Se ci sono più ruoli, aggiungiamo il contatore "(+X)"
              if (roles.length > 1) {
                // Esempio: "Homer Simpson (+15)"
                charName += " (+${roles.length - 1})";
              }
            }
            
            return Actor(
              name: c['name'] ?? "Unknown",
              characterName: charName,
              profileUrl: c['profile_path'] != null 
                  ? 'https://image.tmdb.org/t/p/w185${c['profile_path']}' 
                  : null,
            );
          })
          .toList();
    }

    // Parsing Watch Providers (Logica per estrarre quelli 'flatrate' US)
    List<WatchProvider> providersList = [];
    if (json['watch/providers'] != null && json['watch/providers']['results'] != null && json['watch/providers']['results']['US'] != null) {
      var usProviders = json['watch/providers']['results']['US'];
      if (usProviders['flatrate'] != null) {
         providersList = (usProviders['flatrate'] as List).map((wp) => WatchProvider.fromJson(wp)).toList();
      }
    }

    LastEpisodeInfo? lastEp;
    if (json['last_episode_to_air'] != null) {
      lastEp = LastEpisodeInfo.fromJson(json['last_episode_to_air']);
    }

    return TvShowDetails(
      id: json['id'],
      name: json['name'] ?? 'Untitled',
      seasons: seasonsList,
      posterUrl: posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null,
      backdropUrl: backdropPath != null ? 'https://image.tmdb.org/t/p/w1280$backdropPath' : null,
      tagline: json['tagline'],
      overview: json['overview'] ?? "",
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      firstAirDate: json['first_air_date'],
      status: json['status'] ?? "Unknown",
      numberOfSeasons: json['number_of_seasons'] ?? 0,
      numberOfEpisodes: json['number_of_episodes'] ?? 0,
      genres: genresList,
      networks: networksList,
      creators: creatorsList,
      cast: castList,
      watchProviders: providersList,
      lastEpisode: lastEp,
    );
  }
}

class Season {
  final int id;
  final String name;
  final int seasonNumber;
  final int episodeCount;

  Season({required this.id, required this.name, required this.seasonNumber, required this.episodeCount});

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'],
      name: json['name'] ?? "Season ${json['season_number']}",
      seasonNumber: json['season_number'] ?? 0,
      episodeCount: json['episode_count'] ?? 0,
    );
  }
}

class Episode {
  final int id;
  final String name;
  final int episodeNumber;
  final String? stillUrl;
  final String overview;
  final String? airDate;
  final int runtime;

  Episode({required this.id, required this.name, required this.episodeNumber, this.stillUrl, required this.overview, this.airDate, required this.runtime});

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'],
      name: json['name'] ?? "Episode ${json['episode_number']}",
      episodeNumber: json['episode_number'] ?? 0,
      overview: json['overview'] ?? "",
      stillUrl: json['still_path'] != null ? 'https://image.tmdb.org/t/p/w300${json['still_path']}' : null,
      airDate: json['air_date'],
      runtime: json['runtime'] ?? 0,
    );
  }
}

class Actor {
  final String name;
  final String characterName;
  final String? profileUrl;

  Actor({required this.name, required this.characterName, this.profileUrl});

  factory Actor.fromJson(Map<String, dynamic> json) {
    String? profilePath = json['profile_path'];
    return Actor(
      name: json['name'] ?? "Unknown",
      characterName: json['character'] ?? "Unknown",
      profileUrl: profilePath != null ? 'https://image.tmdb.org/t/p/w185$profilePath' : null,
    );
  }
}

class WatchProvider {
  final String providerName;
  final String logoUrl;

  WatchProvider({required this.providerName, required this.logoUrl});
    factory WatchProvider.fromJson(Map<String, dynamic> json) {
    return WatchProvider(
      providerName: json['provider_name'] ?? "",
      logoUrl: 'https://image.tmdb.org/t/p/w92${json['logo_path']}',
    );
  }
}

class LastEpisodeInfo {
  final String name;
  final int seasonNumber;
  final int episodeNumber;
  final String airDate;

  LastEpisodeInfo({required this.name, required this.seasonNumber, required this.episodeNumber, required this.airDate});
   factory LastEpisodeInfo.fromJson(Map<String, dynamic> json) {
    return LastEpisodeInfo(
      name: json['name'] ?? "Unknown Episode",
      seasonNumber: json['season_number'] ?? 0,
      episodeNumber: json['episode_number'] ?? 0,
      airDate: json['air_date'] ?? "N/A",
    );
  }
}