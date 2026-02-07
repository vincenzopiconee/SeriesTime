class User {
  final String name;
  final double totalHoursWatched;
  final double maxConsecutiveHours;
  final double weekendHours;
  final double nightOwlHours;
  final int uniqueGenresCount;
  List<String> claimedBadgeIds;
  final String? photoUrl;
  int seriesStreak;
  DateTime? lastViewDate;

  User({
    required this.name,
    required this.totalHoursWatched,
    required this.maxConsecutiveHours,
    required this.weekendHours,
    required this.nightOwlHours,
    required this.uniqueGenresCount,
    this.claimedBadgeIds = const [],
    this.photoUrl,
    this.seriesStreak = 0,
    this.lastViewDate,
  });
}
