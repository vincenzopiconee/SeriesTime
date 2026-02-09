import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../models/user_badge.dart';
import '../widgets/notification_banner.dart';
import 'explore_screen.dart';
import 'my_series_screen.dart';
import 'binge_mode_screen.dart';
import 'profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  
  final Set<String> _notifiedBadgeIds = {};
  final List<UserBadge> _bannerQueue = [];
  bool _isBannerShowing = false;

  final List<Widget> _pages = [
    const ExploreScreen(),
    const MySeriesScreen(),
    const BingeModeScreen(),
    const ProfileScreen(),
  ];

  void _showClaimBanner(UserBadge badge) {
    if (_isBannerShowing) {
      _bannerQueue.add(badge);
      return;
    }

    _isBannerShowing = true;
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 15,
        right: 15,
        child: NotificationBanner(
          badge: badge,
          onDismissed: () {
            if (overlayEntry.mounted) {
              overlayEntry.remove();
            }
            _isBannerShowing = false;
            
            if (_bannerQueue.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 300), () {
                 if (mounted) {
                   _showClaimBanner(_bannerQueue.removeAt(0));
                 }
              });
            }
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AppData.userStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;

          if (AppData.currentUser != null) {
             AppData.currentUser?.claimedBadgeIds = List<String>.from(
              data['claimedBadgeIds'] ?? [],
            );
          }

          final allUnclaimed = AppData.getAllUnclaimedBadges();

          for (var badge in allUnclaimed) {
            if (!_notifiedBadgeIds.contains(badge.id)) {
              _notifiedBadgeIds.add(badge.id);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showClaimBanner(badge);
              });
            }
          }
        }

        return Scaffold(
          extendBody: true,
          body: _pages[_selectedIndex],
          bottomNavigationBar: _buildCustomNavbar(),
        );
      },
    );
  }

  Widget _buildCustomNavbar() {
    return Container(
      height: 83,
      padding: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: AppData.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.search, "Explore", 0),
          _navItem(Icons.subscriptions, "My Series", 1),
          _navItem(Icons.track_changes, "Binge Mode", 2),
          _navItem(Icons.person_outline, "Profile", 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5), 
            decoration: BoxDecoration(
              color: isSelected ? AppData.accentColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 27,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}