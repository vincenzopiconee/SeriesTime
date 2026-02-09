import 'package:seriestime/models/actor.dart';

class Episode {
  final int id;
  final String name;
  final int episodeNumber;
  final String? stillUrl;
  final String overview;
  final String? airDate;
  final int runtime;
  final double voteAverage;
  final List<Actor> guestStars;

  Episode({
    required this.id, 
    required this.name, 
    required this.episodeNumber, 
    this.stillUrl, 
    required this.overview, 
    this.airDate, 
    required this.runtime,
    this.voteAverage = 0.0,
    this.guestStars = const [],
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    List<Actor> guests = [];
    if (json['guest_stars'] != null) {
      guests = (json['guest_stars'] as List)
          .map((a) => Actor.fromJson(a))
          .toList();
    }

    return Episode(
      id: json['id'],
      name: json['name'] ?? "Episode ${json['episode_number']}",
      episodeNumber: json['episode_number'] ?? 0,
      overview: json['overview'] ?? "",
      stillUrl: json['still_path'] != null ? 'https://image.tmdb.org/t/p/w500${json['still_path']}' : null, 
      runtime: json['runtime'] ?? 0,
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      guestStars: guests,
    );
  }
}