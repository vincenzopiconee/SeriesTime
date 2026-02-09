class WatchProvider {
  final String providerName;
  final String logoUrl;

  WatchProvider({required this.providerName, required this.logoUrl});
    factory WatchProvider.fromJson(Map<String, dynamic> json) {
    return WatchProvider(
      providerName: json['provider_name'] ?? "",
      logoUrl: 'https://image.tmdb.org/t/p/w92${json['logo_path']}',
    );
  }
}