// models/userbadge.dart
class UserBadge {
  final String id;
  final String title;
  final String imagePath;
  final String iconLabel;
  final double targetHours;
  final String? nextId;

  UserBadge({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.iconLabel,
    required this.targetHours,
    this.nextId,
  });
}
