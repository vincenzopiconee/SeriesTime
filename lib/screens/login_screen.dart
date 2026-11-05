import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/app_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seriestime/screens/main_wrapper_screen.dart';
import 'dart:io';

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
        Uri.parse(
          'https://api.themoviedb.org/3/trending/tv/week?api_key=${AppData.tmdbApiKey}',
        ),
        headers: {
          'User-Agent': 'SeriesTimeApp/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'];

        setState(() {
          _posters = results
              .map((item) {
                String? path = item['poster_path'];
                return path != null
                    ? 'https://image.tmdb.org/t/p/w500$path'
                    : '';
              })
              .where((url) => url.isNotEmpty)
              .toList();
          _posters = [..._posters, ..._posters];
        });
      }
    } catch (e) {
      debugPrint('Error occurred on TMDB posters: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: (!kIsWeb && Platform.isIOS)
              ? '192989615567-ceb6bb8lrdr2vovmraf4lrgsitptb5qr.apps.googleusercontent.com'
              : null,
        );
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        await AppData.initializeData();

        if (!mounted) return;

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        if (e.code != 'popup-closed-by-user' && e.code != 'cancelled') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Access error: ${e.message ?? e.code}")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("An access error occured: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    padding: EdgeInsets.zero,
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
                  Colors.black.withAlpha(200),
                  Colors.transparent,
                  Colors.black.withAlpha(200),
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
                const Text(
                  "SeriesTime",
                  style: TextStyle(
                    color: AppData.backgroundColor,
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    height: 0.8,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 110,
            left: 40,
            right: 40,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signInWithGoogle,
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
                      "LOG IN with Google",
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
