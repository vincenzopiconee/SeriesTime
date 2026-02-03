class Series {
  final int id;
  final String name;
  final String imageUrl;
  final double percentage;
  double totalHours;
  final String episode;
  final String lastEpisodeTitle;
  final String? nextEpisodeAirDate;
  final double seriesDuration; 
  bool isFavorite;
  final bool completed;
  final List<Map<String, dynamic>> watchedEpisodes;

  Series({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.percentage,
    required this.totalHours,
    required this.episode,
    this.lastEpisodeTitle = "",
    this.nextEpisodeAirDate,
    this.seriesDuration = 0.0, 
    this.isFavorite = false,
    this.completed = false,
    this.watchedEpisodes = const [],
  });

  String get timeLabel => "${totalHours}h";
}
