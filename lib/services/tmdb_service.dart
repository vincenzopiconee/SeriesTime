import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/next_episode_info.dart';

class TmdbService {
  static Map<String, dynamic>? mockSeriesData;
  static NextEpisodeInfo? mockNextEpisode;
  static http.Client httpClient = http.Client();

  static Future<double> getSeriesTotalRuntimeFromApi(String seriesName) async {
    if (mockSeriesData != null) {
      return (mockSeriesData!['seriesDuration'] as num).toDouble();
    }
    try {
      final searchUrl =
          "https://api.themoviedb.org/3/search/tv?api_key=${AppData.tmdbApiKey}&query=${Uri.encodeComponent(seriesName)}";
      final searchRes = await httpClient.get(Uri.parse(searchUrl));

      if (searchRes.statusCode == 200) {
        final searchData = json.decode(searchRes.body);
        if (searchData['results'].isNotEmpty) {
          final int seriesId = searchData['results'][0]['id'];

          final detailRes = await httpClient.get(
            Uri.parse(
              "https://api.themoviedb.org/3/tv/$seriesId?api_key=${AppData.tmdbApiKey}&language=it-IT",
            ),
          );
          final data = json.decode(detailRes.body);

          int episodesCount = data['number_of_episodes'] ?? 0;
          int runtime = 45;

          if (data['episode_run_time'] != null &&
              (data['episode_run_time'] as List).isNotEmpty) {
            runtime = data['episode_run_time'][0];
          }

          return (episodesCount * runtime) / 60.0;
        }
      }
    } catch (e) {
      debugPrint("Errore calcolo runtime totale TMDB: $e");
    }
    return 1.0;
  }

  static Future<NextEpisodeInfo?> fetchNextEpisode(int seriesId) async {
    final String url =
        "https://api.themoviedb.org/3/tv/$seriesId?api_key=${AppData.tmdbApiKey}&language=en-US";
    if (mockNextEpisode != null) {
      return mockNextEpisode;
    }
    try {
      final response = await httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nextEpData = data['next_episode_to_air'];

        if (nextEpData == null) return null;

        final String? airDateStr = nextEpData['air_date'];
        if (airDateStr == null) return null;

        final airDate = DateTime.parse(airDateStr);
        final now = DateTime.now();

        if (airDate.isBefore(DateTime(now.year, now.month, now.day))) {
          return null;
        }

        return NextEpisodeInfo(
          name: nextEpData['name'] ?? "TBA",
          episodeLabel:
              "S${nextEpData['season_number']} E${nextEpData['episode_number']}",
          airDate: airDate,
          stillUrl: nextEpData['still_path'] != null
              ? "https://image.tmdb.org/t/p/w500${nextEpData['still_path']}"
              : null,
        );
      }
    } catch (e) {
      debugPrint("Errore fetchNextEpisode per ID $seriesId: $e");
    }
    return null;
  }

  static Future<List<String>> fetchGenresForSeries(int seriesId) async {
    try {
      final response = await httpClient.get(
        Uri.parse(
          "https://api.themoviedb.org/3/tv/$seriesId?api_key=${AppData.tmdbApiKey}",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['genres'] as List)
            .map((g) => g['name'].toString())
            .toList();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchAndCalculateSeriesData(
    int seriesId,
  ) async {
    final String url =
        "https://api.themoviedb.org/3/tv/$seriesId?api_key=${AppData.tmdbApiKey}&language=en-US";

    double totalDurationHours = 0.0;
    String posterUrl = "";
    int avgRuntime = 45;

    try {
      final response = await httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['poster_path'] != null) {
          posterUrl = "https://image.tmdb.org/t/p/w500${data['poster_path']}";
        }

        int numberOfEpisodes = data['number_of_episodes'] ?? 0;

        if (data['episode_run_time'] != null &&
            (data['episode_run_time'] as List).isNotEmpty) {
          avgRuntime = data['episode_run_time'][0];
        }

        int totalMinutes = numberOfEpisodes * avgRuntime;
        totalDurationHours = totalMinutes / 60.0;
      }
    } catch (e) {
      debugPrint("Errore API TMDB: $e");
    }

    return {
      'imageUrl': posterUrl,
      'seriesDuration': totalDurationHours,
      'averageRuntime': avgRuntime,
    };
  }
}
