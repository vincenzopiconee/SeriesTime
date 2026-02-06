import 'package:flutter/material.dart';
import '../models/appdata.dart';
import '../models/userbadge.dart';
import '../models/user.dart';

class BadgeDetailScreen extends StatelessWidget {
  final String categoryTitle;
  final List<UserBadge> milestones;
  final double currentValue;
  final String unit;

  const BadgeDetailScreen({
    super.key,
    required this.categoryTitle,
    required this.milestones,
    required this.currentValue,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    // Troviamo l'ultimo badge sbloccato per l'header
    final List<String> claimedIds = AppData.currentUser?.claimedBadgeIds ?? [];
    final UserBadge currentBadge = milestones.lastWhere(
      (m) => claimedIds.contains(m.id),
      orElse: () => milestones.first,
    );

    bool isSpecial =
        categoryTitle == "Streak" || categoryTitle == "The Perfectionist";

    return Scaffold(
      backgroundColor: AppData.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppData.primaryColor,
        title: Text(
          categoryTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER: Badge attuale e Progresso Totale ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: AppData.whiteColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Transform.scale(
                    scale: isSpecial ? 1.8 : 1.2,
                    child: Image.asset(
                      currentBadge.imagePath,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${currentValue.toStringAsFixed(1)}$unit",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppData.primaryColor,
                    ),
                  ),
                  Text(
                    "Total Progress",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- LISTA LIVELLI (Milestones) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mission Milestones",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  ...milestones.map((m) {
                    bool isUnlocked = claimedIds.contains(m.id);
                    double milestoneProgress = (currentValue / m.targetHours)
                        .clamp(0.0, 1.0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isUnlocked
                              ? AppData.primaryColor
                              : Colors.grey[300]!,
                          width: isUnlocked ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: isUnlocked ? 1.0 : 0.4,
                            child: Image.asset(
                              m.imagePath,
                              width: 50,
                              height: 50,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Level: ${m.iconLabel}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isUnlocked
                                            ? AppData.primaryColor
                                            : Colors.black54,
                                      ),
                                    ),
                                    if (isUnlocked)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppData.primaryColor,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: milestoneProgress,
                                  backgroundColor: Colors.grey[200],
                                  color: isUnlocked
                                      ? AppData.primaryColor
                                      : AppData.accentColor,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
