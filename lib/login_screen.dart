import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'models/appdata.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late ScrollController _scrollController;
  List<String> _posters = [];
  Timer? _scrollTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchPosters();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients && _posters.isNotEmpty) {
        double currentScroll = _scrollController.offset;
        double maxScroll = _scrollController.position.maxScrollExtent;

        double nextScroll = currentScroll + 1.0;

        if (nextScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(nextScroll);
        }
      }
    });
  }

  Future<void> _fetchPosters() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.tvmaze.com/shows'),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _posters = data
              .take(30)
              .map((s) => s['image']?['medium']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toList();
          _posters = [..._posters, ..._posters];
        });
      }
    } catch (e) {
      print('Error occured on poster: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true); // Attiva il caricamento
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false); // Utente ha annullato
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        await AppData.initializeData();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } catch (e) {
      print("Errore durante il login Google: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Errore durante l'accesso: $e")));
      }
    } finally {
      if (mounted)
        setState(
          () => _isLoading = false,
        ); // Disattiva il caricamento in ogni caso
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _posters.isEmpty
              ? Container(color: Colors.black)
              : Opacity(
                  opacity: 0.4,
                  child: GridView.builder(
                    controller: _scrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: _posters.length,
                    itemBuilder: (context, index) => Image.network(
                      _posters[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[900]),
                    ),
                  ),
                ),

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

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 200, height: 200),
                const SizedBox(height: 20),
                const Text(
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

          // Modifica il pulsante esistente
          Positioned(
            bottom: 120,
            left: 40,
            right: 40,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _signInWithGoogle, // Disabilita se carica
              style: ElevatedButton.styleFrom(
                backgroundColor: AppData.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "LOG IN WITH GOOGLE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),

          // Aggiungi questo in fondo allo Stack (dopo l'ultimo Positioned)
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Scura lo sfondo
              child: const Center(
                child: CircularProgressIndicator(color: AppData.primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
