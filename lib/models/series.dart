class Series {
  final String name;
  final String imageUrl;
  final double percentage;
  double totalHours;
  final String episode;
  final List<Map<String, dynamic>> watchedEpisodes;
  Series({
    required this.name,
    required this.imageUrl,
    required this.percentage,
    required this.totalHours,
    required this.episode,
    this.watchedEpisodes = const [],
  });

  String get timeLabel => "${totalHours}h";
}
