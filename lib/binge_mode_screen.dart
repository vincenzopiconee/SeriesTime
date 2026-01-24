import 'package:flutter/material.dart';

class BingeModeScreen extends StatelessWidget {
  const BingeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F0EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "BINGE MODE",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: 120,
        ),
        child: Column(
          children: [
            _buildAchievementCard(
              title: "The Marathoner",
              description:
                  "Reach 20 days of total watch time. Your dedication is admirable.",
              progressText: "10d 3h 2m / 20d 00h 00m",
              progressValue: 0.5,
              imageUrl:
                  "https://static.tvmaze.com/uploads/images/medium_portrait/497/1243533.jpg",
              iconLabel: "20G",
            ),
            const SizedBox(height: 20),
            _buildAchievementCard(
              title: "Pure Obsession",
              description:
                  "Watch the same TV series for 3 consecutive hours without interruptions.",
              progressText: "2h 50m / 3h 00m",
              progressValue: 0.9,
              imageUrl:
                  "https://static.tvmaze.com/uploads/images/medium_portrait/498/1245341.jpg",
              iconLabel: "3H",
            ),
            const SizedBox(height: 20),
            _buildAchievementCard(
              title: "Weekend Warrior",
              description: "Watch 8 hours of content within 3 days.",
              progressText: "7h 30m / 8h 00m",
              progressValue: 0.92,
              imageUrl:
                  "https://static.tvmaze.com/uploads/images/medium_portrait/495/1238914.jpg",
              iconLabel: "8H / 3G",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard({
    required String title,
    required String description,
    required String progressText,
    required double progressValue,
    required String imageUrl,
    required String iconLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F0EB),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF2D3748), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  iconLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 45,
                  width: 45,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 30,
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 15),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progressValue,
                        child: Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B261A),
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      progressText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
