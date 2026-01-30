// models/user.dart
class User {
  final String name;
  final double totalHoursWatched;
  final double maxConsecutiveHours;
  final double weekendHours;
  final bool notification;

  User({
    required this.name,
    required this.totalHoursWatched,
    required this.maxConsecutiveHours,
    required this.weekendHours,
    required this.notification,
  });
}
