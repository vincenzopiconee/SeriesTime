import 'package:flutter/material.dart';
import 'package:seriestime/models/actor.dart';
import 'package:seriestime/models/app_data.dart';
import 'package:seriestime/models/episode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:seriestime/models/user.dart';
import 'series_detail_screen.dart'; 

class EpisodeDetailScreen extends StatelessWidget {
  final String seriesName;
  final int seriesId; 
  final int seasonNumber;
  final Episode episode;

  const EpisodeDetailScreen({
    super.key,
    required this.seriesName,
    required this.seriesId, 
    required this.seasonNumber,
    required this.episode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: AppData.userStream(),
      builder: (context, userSnapshot) {
        
        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          AppData.currentUser = User(
            name: userData['name'] ?? "User",
            totalHoursWatched: (userData['totalHoursWatched'] ?? 0).toDouble(),
            maxConsecutiveHours: (userData['maxConsecutiveHours'] ?? 0).toDouble(),
            weekendHours: (userData['weekendHours'] ?? 0).toDouble(),
            nightOwlHours: (userData['nightOwlHours'] ?? 0).toDouble(),
            uniqueGenresCount: (userData['uniqueGenresCount'] ?? 0).toInt(),
            seriesStreak: userData['seriesStreak'] ?? 0,
            claimedBadgeIds: List<String>.from(userData['claimedBadgeIds'] ?? []),
            photoUrl: userData['photoUrl'] ?? auth.FirebaseAuth.instance.currentUser?.photoURL,
          );
        }

        return Scaffold(
          backgroundColor: AppData.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppData.primaryColor,
            elevation: 0,
            title: FittedBox(
              fit: BoxFit.scaleDown, 
              child: Text(
                "$seriesName - S$seasonNumber E${episode.episodeNumber}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Colors.white, 
                ),
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderImage(),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          "S$seasonNumber E${episode.episodeNumber}",
                          style: const TextStyle(
                            color: AppData.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    if (episode.voteAverage > 0) 
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 2),
                          Text(
                            episode.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeriesDetailScreen(
                          seriesId: seriesId,
                          seriesName: seriesName,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    seriesName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      decoration: TextDecoration.underline, 
                      decorationColor: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  episode.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _buildBadge(Icons.calendar_today, episode.airDate ?? "Unknown"),
                    const SizedBox(width: 12),
                    if (episode.runtime > 0) _buildBadge(Icons.access_time, "${episode.runtime} min"),
                    
                    const Spacer(flex: 5),

                    _buildWatchedToggle(),

                    const Spacer(flex: 1),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  "Overview",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppData.primaryColor
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppData.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))
                      ]
                  ),
                  child: Text(
                    episode.overview.isNotEmpty ? episode.overview : "No description available.",
                    style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.4),
                  ),
                ),

                const SizedBox(height: 24),

                if (episode.guestStars.isNotEmpty) ...[
                  const Text(
                    "Guest Stars",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppData.primaryColor
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 215, 
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: episode.guestStars.length,
                      itemBuilder: (context, index) {
                        final actor = episode.guestStars[index];
                        return _buildCastCard(actor);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildWatchedToggle() {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    bool isFuture = false;
    if (episode.airDate != null && episode.airDate!.isNotEmpty) {
      DateTime airDate = DateTime.parse(episode.airDate!);
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);
        if (airDate.isAfter(today)) {
          isFuture = true;
        }
    }

    if (isFuture) {
      return Row (
        children: [
          Text("Not Released", style: TextStyle(
            fontSize: 16,
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(width: 8),
          Icon(Icons.schedule, size: 36, color: Colors.grey[400])
        ],

      );
    }
                
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('series')
            .doc(seriesName)
            .collection('seasons')
            .doc('Season $seasonNumber')
            .collection('episodes')
            .doc('Episode ${episode.episodeNumber}')
            .snapshots(),
        builder: (context, snapshot) {
          bool isWatched = false;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            isWatched = data['watched'] ?? false;
          }

          return Row (
            children: [
              Text(
                isWatched ? "Watched" : "Not Watched",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  AppData.toggleEpisodeWatched(
                    seriesName: seriesName,
                    seriesId: seriesId,
                    seasonNum: seasonNumber,
                    episodeNum: episode.episodeNumber,
                    episodeTitle: episode.name,
                    isWatched: !isWatched, 
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isWatched ? AppData.accentColor : AppData.accentColor.withAlpha(30),
                    border: Border.all(
                      color: isWatched ? AppData.accentColor : Colors.grey.shade400,
                    )
                  ),
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: isWatched ? Colors.white : Colors.grey[500],
                  ),
                ),
              )
            ]
          );
        }
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: episode.stillUrl != null
            ? Image.network(episode.stillUrl!, fit: BoxFit.cover)
            : Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppData.accentColor.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppData.accentColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppData.accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCastCard(Actor actor) {
    return Container(
      width: 115,
      margin: const EdgeInsets.only(right: 10, bottom: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppData.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox( 
            height: 135, 
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: actor.profileUrl != null
                  ? Image.network(actor.profileUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.grey[300], child: const Icon(Icons.person, color: Colors.grey, size: 105)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            actor.name,
            maxLines: 2, 
            overflow: TextOverflow.ellipsis, 
            style: const TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: AppData.primaryColor,
              height: 1.1 
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            actor.characterName,
            maxLines: 4, 
            overflow: TextOverflow.ellipsis, 
            style: TextStyle(
              fontSize: 10, 
              color: Colors.grey[600],
              height: 1.1
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}