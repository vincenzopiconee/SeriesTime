import 'package:flutter/material.dart';
import 'profile_screen.dart';

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
        scaffoldBackgroundColor: const Color(0xFFF2F0EB), // Sfondo panna
      ),
      home: const ProfileScreen(),
    );
  }
}