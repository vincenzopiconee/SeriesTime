class TvShow {
  final int id;
  final String name;
  final String? posterUrl;
  final String year;
  final List<String> genres;
  final List<int> genreIds;
  final String? country;
  final double voteAverage;
  final String overview;

  TvShow({
    required this.id,
    required this.name,
    this.posterUrl,
    required this.year,
    required this.genres,
    required this.genreIds, 
    this.country,
    required this.voteAverage,
    required this.overview,
  });

  factory TvShow.fromJson(Map<String, dynamic> json) {
    String? imgPath = json['poster_path'];
    String? fullImgUrl = imgPath != null ? 'https://image.tmdb.org/t/p/w500$imgPath' : null;

    String yearStr = "";
    if (json['first_air_date'] != null && json['first_air_date'].toString().length >= 4) {
      yearStr = json['first_air_date'].toString().substring(0, 4);
    }

    List<String> genreNames = [];
    List<int> gIds = [];
    
    if (json['genre_ids'] != null) {
      for (var id in json['genre_ids']) {
        gIds.add(id);
        if (tmdbGenres.containsKey(id)) {
          genreNames.add(tmdbGenres[id]!);
        }
      }
    }

    String? countryStr;
    if (json['origin_country'] != null && (json['origin_country'] as List).isNotEmpty) {
      countryStr = json['origin_country'][0];
    }

    return TvShow(
      id: json['id'],
      name: json['name'] ?? 'Untitled',
      posterUrl: fullImgUrl,
      year: yearStr,
      genres: genreNames,
      genreIds: gIds,
      country: countryStr,
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      overview: json['overview'] ?? "",
    );
  }
}

const Map<int, String> tmdbGenres = {
  10759: "Action & Adventure",
  16: "Animation",
  35: "Comedy",
  80: "Crime",
  99: "Documentary",
  18: "Drama",
  10751: "Family",
  10762: "Kids",
  9648: "Mystery",
  10763: "News",
  10764: "Reality",
  10765: "Sci-Fi & Fantasy",
  10766: "Soap",
  10767: "Talk",
  10768: "War & Politics",
  37: "Western",
};

class Genre {
  final int id;
  final String name;
  Genre({required this.id, required this.name});
}
