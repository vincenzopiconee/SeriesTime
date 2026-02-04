import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seriestime/firebase_options.dart';
import 'package:seriestime/models/auth_gate.dart';
import 'package:seriestime/screens/my_series_screen.dart';
import 'screens/profile_screen.dart';
import 'models/appdata.dart';
import 'screens/binge_mode_screen.dart';
import 'package:flutter/services.dart';
import 'screens/explore_screen.dart';
import 'models/userbadge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  ); //disable the bottom android navigation bar
  //await AppData.initializeData();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SeriesTime',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppData.primaryColor),
        useMaterial3: true,
        textTheme: GoogleFonts.firaSansCondensedTextTheme(),
        scaffoldBackgroundColor: AppData.backgroundColor,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  UserBadge? _lastNotifiedBadge;
  bool _isBannerShowing = false;

  final List<Widget> _pages = [
    const ExploreScreen(),
    const MySeriesScreen(),
    const BingeModeScreen(),
    const ProfileScreen(),
  ];
  void _showClaimBanner(UserBadge badge) {
    if (_isBannerShowing) return;
    _isBannerShowing = true;
    _lastNotifiedBadge = badge;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 15,
        right: 15,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: -100.0, end: 0.0),
          curve: Curves.bounceOut,
          builder: (context, value, child) =>
              Transform.translate(offset: Offset(0, value), child: child),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppData.accentColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(badge.imagePath, width: 65, height: 65),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "New Reward Available!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "You have a badge ready to claim!",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
      _isBannerShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AppData.userStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;

          AppData.currentUser?.claimedBadgeIds = List<String>.from(
            data['claimedBadgeIds'] ?? [],
          );

          final unclaimed = AppData.getFirstUnclaimedBadge();

          if (unclaimed != null && unclaimed.id != _lastNotifiedBadge?.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showClaimBanner(unclaimed);
            });
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
      height: 85,
      margin: const EdgeInsets.only(bottom: 0, left: 0, right: 0),
      padding: const EdgeInsets.only(bottom: 26),
      decoration: BoxDecoration(
        color: AppData.primaryColor,
        //borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
          // Usiamo un Container con dimensioni fisse o padding uguale per entrambi gli stati
          Container(
            padding: const EdgeInsets.all(6), // Stesso padding per tutti
            decoration: BoxDecoration(
              // Selezionato: Colore Accent. Non selezionato: Trasparente.
              color: isSelected ? AppData.accentColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              // Selezionato: Bianco. Non selezionato: Bianco opaco (white70).
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
