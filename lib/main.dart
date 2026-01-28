import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seriestime/firebase_options.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'models/appdata.dart';
import 'binge_mode_screen.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  ); //disable the bottom andrord navigation bar
  await AppData.initializeData();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TV Series Tracker',
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
      home: const LoginScreen(),
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

  final List<Widget> _pages = [
    const ProfileScreen(),
    const Center(child: Text("Explore")),
    const Center(child: Text("Favourites")),
    const BingeModeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildCustomNavbar(),
    );
  }

  Widget _buildCustomNavbar() {
    return Container(
      height: 85,
      margin: const EdgeInsets.only(bottom: 0, left: 0, right: 0),
      decoration: BoxDecoration(
        color: AppData.primaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.person_outline, "Profile", 0),
          _navItem(Icons.search, "Explore", 1),
          _navItem(Icons.star_border, "Favourites", 2),
          _navItem(Icons.track_changes, "Binge Mode", 3),
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
          if (isSelected)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppData.accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            )
          else
            Icon(icon, color: Colors.white70, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
