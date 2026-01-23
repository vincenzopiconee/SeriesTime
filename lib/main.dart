import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B261A)),
        useMaterial3: true,
        // Applichiamo il font globale
        textTheme: GoogleFonts.firaSansCondensedTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF2F0EB),
      ),
      // Impostiamo MainWrapper come schermata iniziale
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
    const Center(child: Text("Binge Mode")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ExtendBody permette alla navbar di sovrapporsi leggermente se necessario
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildCustomNavbar(),
    );
  }

  Widget _buildCustomNavbar() {
    return Container(
      height: 85,
      margin: const EdgeInsets.only(
        bottom: 20,
        left: 15,
        right: 15,
      ), // La solleva un po' per un look moderno
      decoration: BoxDecoration(
        color: const Color(0xFF8B261A),
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
                color: Color(0xFF2D3748),
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
