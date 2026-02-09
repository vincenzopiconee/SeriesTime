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