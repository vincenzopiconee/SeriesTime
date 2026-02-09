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