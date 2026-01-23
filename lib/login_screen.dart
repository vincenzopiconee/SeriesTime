import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart'; // Per navigare verso MainWrapper

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late ScrollController _scrollController;
  List<String> _posters = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchPosters();

    // Timer per far muovere lo sfondo automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (_scrollController.hasClients) {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;

      // Scorrimento fluido infinito
      _scrollController
          .animateTo(
            maxScroll == currentScroll ? 0 : maxScroll,
            duration: Duration(seconds: 40),
            curve: Curves.linear,
          )
          .then((_) => _startScrolling());
    }
  }

  Future<void> _fetchPosters() async {
    // Pesca serie popolari per lo sfondo
    final response = await http.get(Uri.parse('https://api.tvmaze.com/shows'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        _posters = data
            .take(30)
            .map((s) => s['image']['medium'].toString())
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Sfondo Animato di Poster
          Opacity(
            opacity: 0.4,
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
              ),
              itemCount: _posters.length,
              itemBuilder: (context, index) =>
                  Image.network(_posters[index], fit: BoxFit.cover),
            ),
          ),

          // 2. Gradiente per scurire il fondo
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                  Colors.black,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Contenuto Centrale (Logo e Titolo)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png', // Il percorso deve essere identico
                  width: 150, // Regola la grandezza come vuoi
                  height: 150,
                ),
                SizedBox(height: 20),
                Text(
                  "SERIES\nTIME",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottone in basso
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainWrapper()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B261A),
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "LOG IN/ SIGN IN",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
