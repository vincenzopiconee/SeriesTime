import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  late bool isNotificationsEnabled;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    isNotificationsEnabled = AppData.currentUser?.notification ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final user = AppData.currentUser;

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
            // Avatar
            CircleAvatar(
              radius: 45,
              backgroundColor: AppData.avatarColor,
              backgroundImage:
                  user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null
                  ? const Icon(Icons.person, size: 55, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? "User",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppData.primaryColor,
              ),
            ),
            const SizedBox(height: 25),

            // App Settings
            _buildSectionCard(
              title: "App Settings",
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Notifications",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    Switch(
                      value: isNotificationsEnabled,
                      activeColor: AppData.whiteColor,
                      activeTrackColor: AppData.accentColor,
                      inactiveThumbColor: Colors.grey,
                      trackOutlineColor:
                          MaterialStateProperty.all(Colors.transparent),
                      onChanged: (val) => _updateNotificationPreference(val),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Account
            _buildSectionCard(
              title: "Account",
              children: [
                _buildSettingsRow("Edit Profile", Icons.edit),
                const Divider(),
                _buildSettingsRow("Privacy Policy", Icons.lock),
              ],
            ),

            const SizedBox(height: 30),

            // Logout Button
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

            // Delete Account Button / Loading
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
                  )
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

  Widget _buildSettingsRow(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Future<void> _updateNotificationPreference(bool value) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    setState(() {
      isNotificationsEnabled = value;
    });
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({'notification': value});

      if (AppData.currentUser != null) {
        AppData.currentUser!.notification = value;
      }
    } catch (e) {
      debugPrint("An error occured during the notification updating: $e");
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // --- DELETE ACCOUNT LOGIC ---
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 10),
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

  // --- FUNZIONE DI PULIZIA PROFONDA ---
  // Elimina ricorsivamente Series -> Seasons -> Episodes
  Future<void> _deleteFullSeriesData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    
    // 1. Ottieni riferimento alla collezione 'series'
    final seriesRef = firestore.collection('users').doc(uid).collection('series');
    final seriesSnapshot = await seriesRef.get();

    // 2. Itera su ogni serie
    for (var seriesDoc in seriesSnapshot.docs) {
      
      // 2.a Ottieni riferimento a 'seasons' dentro la serie
      final seasonsRef = seriesDoc.reference.collection('seasons');
      final seasonsSnapshot = await seasonsRef.get();

      // 3. Itera su ogni stagione
      for (var seasonDoc in seasonsSnapshot.docs) {
        
        // 3.a Ottieni riferimento a 'episodes' dentro la stagione
        final episodesRef = seasonDoc.reference.collection('episodes');
        final episodesSnapshot = await episodesRef.get();

        // 4. ELIMINA TUTTI GLI EPISODI
        for (var episodeDoc in episodesSnapshot.docs) {
          await episodeDoc.reference.delete();
        }

        // 5. ELIMINA IL DOCUMENTO STAGIONE
        await seasonDoc.reference.delete();
      }

      // 6. ELIMINA IL DOCUMENTO SERIE
      await seriesDoc.reference.delete();
    }
  }

  Future<void> _performDelete() async {
    setState(() => _isDeleting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. PULIZIA PROFONDA E RICORSIVA DEI DATI
      await _deleteFullSeriesData(user.uid);

      // 2. ELIMINAZIONE DOCUMENTO UTENTE PRINCIPALE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // 3. ELIMINAZIONE ACCOUNT AUTH
      await user.delete();

      // 4. Pulizia Token Locali
      await GoogleSignIn().signOut();

      // 5. Navigazione al Login
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );

    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false, 
            builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppData.whiteColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppData.accentColor, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Security Check",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppData.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "For security reasons, you need to sign in again to delete your account.\n\nPlease tap 'Log Out' below, sign in again, and then delete your account immediately.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _handleLogout(); // LOGOUT AUTOMATICO
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppData.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("Log Out & Retry"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text("Cancel"),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      } else {
        if (mounted) _showErrorDialog("Error", "Could not delete account: ${e.message}");
      }
    } catch (e) {
      debugPrint("Generic delete error: $e");
      if (mounted) _showErrorDialog("Error", "An unexpected error occurred.");
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}