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
    this.episode = "S1 E1",
  });

  String get timeLabel => "${totalHours}h";
}
