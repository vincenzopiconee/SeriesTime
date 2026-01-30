// models/user.dart
class User {
  final String name;
  double totalHoursWatched;
  final int maxConsecutiveHours;
  final int weekendHours;
  final bool notification;

  User({
    required this.name,
    required this.totalHoursWatched,
    required this.maxConsecutiveHours,
    required this.weekendHours,
    required this.notification,
  });
}
