class NextEpisodeInfo {
  final String name;
  final String episodeLabel;
  final DateTime airDate;
  final String? stillUrl;

  NextEpisodeInfo({
    required this.name,
    required this.episodeLabel,
    required this.airDate,
    this.stillUrl,
  });

  int get daysLeft {
    final now = DateTime.now();
    // Calcoliamo la differenza in giorni dalla mezzanotte di oggi
    final today = DateTime(now.year, now.month, now.day);
    final difference = airDate.difference(today);
    return difference.inDays;
  }
}