class Actor {
  final String name;
  final String characterName;
  final String? profileUrl;

  Actor({required this.name, required this.characterName, this.profileUrl});

  factory Actor.fromJson(Map<String, dynamic> json) {
    String? profilePath = json['profile_path'];
    return Actor(
      name: json['name'] ?? "Unknown",
      characterName: json['character'] ?? "Unknown",
      profileUrl: profilePath != null ? 'https://image.tmdb.org/t/p/w185$profilePath' : null,
    );
  }
}