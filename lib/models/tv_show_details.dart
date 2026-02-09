import 'package:seriestime/models/actor.dart';
import 'package:seriestime/models/last_episode_info.dart';
import 'package:seriestime/models/season.dart';
import 'package:seriestime/models/watch_provider.dart';

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
  final List<Season> seasons;

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
          .where((s) => s.seasonNumber > 0)
          .toList();
    }

    List<Actor> castList = [];
    
    if (json['aggregate_credits'] != null && json['aggregate_credits']['cast'] != null) {
      castList = (json['aggregate_credits']['cast'] as List)
          .map((c) {
            String charName = "Unknown";
            
            if (c['roles'] != null && (c['roles'] as List).isNotEmpty) {
              final roles = c['roles'] as List;
              
              charName = roles[0]['character']; 

              if (roles.length > 1) {
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

