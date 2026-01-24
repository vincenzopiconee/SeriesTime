import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SeriesProgressScreen extends StatefulWidget {
  const SeriesProgressScreen({super.key});

  @override
  State<SeriesProgressScreen> createState() => _SeriesProgressScreenState();
}

class _SeriesProgressScreenState extends State<SeriesProgressScreen> {
  final Map<String, String> _seriesImages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeriesImages();
  }

  Future<void> _loadSeriesImages() async {
    final List<String> showNames = ["Breaking Bad", "Squid Game"];

    try {
      for (String name in showNames) {
        final response = await http.get(
          Uri.parse('https://api.tvmaze.com/singlesearch/shows?q=$name'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (mounted) {
            setState(() {
              _seriesImages[name] = data['image'] != null
                  ? data['image']['medium']
                  : '';
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Errore: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F0EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "MY SERIES\nPROGRESS",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B261A)),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                _buildProgressCard(
                  title: "Breaking Bad",
                  episode: "S5 E9",
                  percentage: 0.92,
                  totalHours: "57h",
                  timeLeft: "7h left",
                  imageUrl: _seriesImages["Breaking Bad"] ?? "",
                ),
                const SizedBox(height: 15),
                _buildProgressCard(
                  title: "Squid Game",
                  episode: "S3 E6",
                  percentage: 1.0,
                  totalHours: "24h",
                  timeLeft: "Finished",
                  imageUrl: _seriesImages["Squid Game"] ?? "",
                  isFinished: true,
                ),
                const SizedBox(height: 130),
              ],
            ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String episode,
    required double percentage,
    required String totalHours,
    required String timeLeft,
    required String imageUrl,
    bool isFinished = false,
  }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D3748), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: SizedBox(
              width: 80,
              height: double.infinity,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[300]),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.downloading, color: Colors.white),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        episode,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isFinished)
                        _badge("Finished")
                      else
                        _percentageLabel(percentage),
                    ],
                  ),
                  _progressBar(percentage),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        totalHours,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        timeLeft,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _percentageLabel(double percentage) {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 14, color: Colors.grey),
        Text(
          " ${(percentage * 100).toInt()}%",
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _progressBar(double percentage) {
    return Stack(
      children: [
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        FractionallySizedBox(
          widthFactor: percentage,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF8B261A),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
