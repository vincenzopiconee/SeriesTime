import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appdata.dart';
import '../models/userbadge.dart';

class AllBadgesScreen extends StatefulWidget {
  const AllBadgesScreen({super.key});

  @override
  State<AllBadgesScreen> createState() => _AllBadgesScreenState();
}

class _AllBadgesScreenState extends State<AllBadgesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppData.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppData.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppData.whiteColor,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Badges",
          style: TextStyle(
            color: AppData.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: AppData.userStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> claimedIds = List<String>.from(
            userData['claimedBadgeIds'] ?? [],
          );

          final List<UserBadge> allUnlocked = [
            ...AppData.marathonerMilestones,
            ...AppData.obsessionMilestones,
            ...AppData.weekendMilestones,
            ...AppData.streakMilestones,
            ...AppData.completionistMilestones,
            ...AppData.nightOwlMilestones,
            ...AppData.genreMilestones,
          ].where((badge) => claimedIds.contains(badge.id)).toList();

          if (allUnlocked.isEmpty) {
            return const Center(
              child: Text(
                "No badges claimed yet.\nKeep watching to unlock rewards!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            radius: const Radius.circular(10),
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 16,
              ),
              itemCount: allUnlocked.length,
              itemBuilder: (context, index) {
                final badge = allUnlocked[index];
                bool shouldScale =
                    badge.title == "Streak" ||
                    badge.title == "The Perfectionist";

                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppData.whiteColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Transform.scale(
                            scale: shouldScale ? 1.5 : 1.0,
                            child: Image.asset(
                              badge.imagePath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badge.title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppData.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge.iconLabel,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
