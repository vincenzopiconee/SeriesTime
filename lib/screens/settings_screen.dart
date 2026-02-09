import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import '../models/appdata.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final user = AppData.currentUser;
    final String userEmail = FirebaseAuth.instance.currentUser?.email ?? "No email";

    return Scaffold(
      backgroundColor: AppData.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppData.primaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppData.whiteColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppData.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          children: [
            Text(
              user?.name ?? "User",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppData.primaryColor,
              ),
            ),
            Text(
                userEmail,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),

            const SizedBox(height: 40),

            _buildSectionCard(
              title: "About",
              children: [
                _buildInfoRow("App Version", "1.0.0"),
                const Divider(),
                _buildInfoRow("Data Source", "Provided by TMDB"),
              ],
            ),

            const SizedBox(height: 50),

            ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppData.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
              ),
              child: const Text(
                "LOGOUT",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),

            const SizedBox(height: 15),

            if (_isDeleting)
              const Column (
                children: [
                  SizedBox(height: 15),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppData.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Cleaning Database...",
                    style: TextStyle(
                    color: AppData.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    ),
                  ),
                ],
              )
            else
              TextButton(
                onPressed: _confirmDeleteAccount,
                child: const Text(
                  "Delete Account",
                  style: TextStyle(
                    color: AppData.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppData.whiteColor,
        border: Border.all(color: AppData.accentColor, width: 2),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppData.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    // --- MODIFICA: Pulisci i dati locali ---
    AppData.resetData();
    // ---------------------------------------
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppData.whiteColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppData.accentColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Delete Account",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppData.primaryColor,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Are you sure you want to delete your account? This action cannot be undone and will delete ALL your data permanently.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _performDelete();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppData.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFullSeriesData(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final seriesRef = firestore.collection('users').doc(uid).collection('series');
      final seriesSnapshot = await seriesRef.get();

      for (var seriesDoc in seriesSnapshot.docs) {
        try {
          final seasonsRef = seriesDoc.reference.collection('seasons');
          final seasonsSnapshot = await seasonsRef.get();

          for (var seasonDoc in seasonsSnapshot.docs) {
            final episodesRef = seasonDoc.reference.collection('episodes');
            final episodesSnapshot = await episodesRef.get();

            for (var episodeDoc in episodesSnapshot.docs) {
              await episodeDoc.reference.delete();
            }
            await seasonDoc.reference.delete();
          }
          await seriesDoc.reference.delete();
        } catch (innerError) {
          debugPrint("Skipping partial data deletion: $innerError");
        }
      }
    } catch (e) {
      debugPrint("Data cleanup skipped: $e");
    }
  }

  Future<void> _performDelete() async {
    setState(() => _isDeleting = true);
    
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
      return;
    }

    try {
      await _deleteFullSeriesData(user.uid);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
    } catch (dbError) {
      debugPrint("Database cleanup skipped/failed: $dbError");
    }

    try {
      await user.delete();
      try {
        await GoogleSignIn().signOut();
      } catch (e) {
        debugPrint("Google SignOut error: $e");
      }

      // --- MODIFICA: Pulisci i dati locali ---
      AppData.resetData();
      // ---------------------------------------

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }

    } catch (e) {
      String errorCode = '';
      String errorMessage = e.toString();

      if (e is FirebaseAuthException) {
        errorCode = e.code;
        errorMessage = e.message ?? errorMessage;
      } else if (e is PlatformException) {
        errorCode = e.code;
        errorMessage = e.message ?? errorMessage;
      }

      if (errorCode == 'requires-recent-login') {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Dialog(
              // ... (Logica Dialog invaiata)
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Security Check", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    const Text("Please log in again to delete your account.", textAlign: TextAlign.center),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _handleLogout();
                      },
                      child: const Text("Log Out & Retry"),
                    ),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel"))
                  ],
                ),
              ),
            ),
          );
        }
      } else if (errorCode == 'user-not-found') {
        if (mounted) {
           Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog("Error", "Could not delete account: $errorMessage");
        }
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }
}