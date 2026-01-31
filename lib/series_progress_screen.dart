import 'package:flutter/material.dart';
import 'models/appdata.dart';
import 'models/series.dart';

class SeriesProgressScreen extends StatelessWidget {
  const SeriesProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppData.currentUser == null) {
      return const Scaffold(
        backgroundColor: AppData.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Series> progressList = List.from(AppData.userSeries);
    progressList.sort(
      (a, b) => b.percentage.compareTo(a.percentage),
    ); //List sorted by percentage

     return GestureDetector(
    onHorizontalDragUpdate: (details) {
      if (details.delta.dx > 18) { 
        Navigator.pop(context);
      }
    },
    child: Scaffold(
      backgroundColor: AppData.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppData.accentColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "MY PROGRESS",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 27,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: progressList.length,
        itemBuilder: (context, index) {
          final series = progressList[index];

          double hoursSeen = series.totalHours ;
          double totalSeriesDuration = series.percentage > 0 
      ? hoursSeen / series.percentage 
      : hoursSeen;
          double hoursLeft = totalSeriesDuration - hoursSeen;

          String seenText = "${formatHours(hoursSeen)} seen";
          String leftText;
          if (series.percentage >= 1.0) {
            leftText = "Finished";
          } else {
            leftText = "${formatHours(hoursLeft)} left";
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _buildProgressCard(
              title: series.name,
              episode: series.episode,
              percentage: series.percentage,
              totalHours: seenText,
              timeLeft: leftText,
              imageUrl: series.imageUrl,
              isFinished: series.percentage >= 1.0,
            ),
          );
        },
      ),
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
        border: Border.all(color: AppData.accentColor, width: 2),
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
          Container(
            margin: const EdgeInsets.all(10),
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppData.accentColor, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie_creation_outlined),
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
        color: AppData.accentColor,
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
              color: AppData.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
  String formatHours(double totalHours) {
  if (totalHours <= 0) return "0m";
  int h = totalHours.toInt(); 
  int m = ((totalHours - h) * 60).round(); 
  
  if (h == 0) return "${m}m";
  if (m == 0) return "${h}h";
  return "${h}h ${m}m";
}
}
