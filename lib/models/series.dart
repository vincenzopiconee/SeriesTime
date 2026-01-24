class Series {
  final String name;
  final String imageUrl;
  final double percentage;
  final int totalHours;
  final String episode;

  Series({
    required this.name,
    required this.imageUrl,
    required this.percentage,
    required this.totalHours,
    required this.episode,
  });

  String get timeLabel => "${totalHours}h";
}
