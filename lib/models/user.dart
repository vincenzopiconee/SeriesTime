class User {
  final String name;
  final double totalHoursWatched;
  final double maxConsecutiveHours;
  final double weekendHours;
  final double nightOwlHours;
  final int uniqueGenresCount;
  final List<String> claimedBadgeIds;
  bool notification;
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
    required this.notification,
    this.photoUrl,
    this.seriesStreak = 0,
    this.lastViewDate,
  });
}
