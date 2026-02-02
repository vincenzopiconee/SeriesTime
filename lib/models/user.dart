class User {
  final String name;
  final double totalHoursWatched;
  final double maxConsecutiveHours;
  final double weekendHours;
  bool notification;
  final String? photoUrl;

  User({
    required this.name,
    required this.totalHoursWatched,
    required this.maxConsecutiveHours,
    required this.weekendHours,
    required this.notification,
    this.photoUrl,
  });
}
