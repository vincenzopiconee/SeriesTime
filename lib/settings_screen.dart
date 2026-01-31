import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'models/appdata.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isNotificationsEnabled;

  @override
  void initState() {
    super.initState();

    isNotificationsEnabled = AppData.currentUser?.notification ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final user = AppData.currentUser;
    return GestureDetector(
    onHorizontalDragUpdate: (details) {
      if (details.delta.dx > 18) { 
        Navigator.pop(context);
      }
    },
    child: Scaffold(
      backgroundColor: AppData.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppData.accentColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
             CircleAvatar(
              radius: 45,
              backgroundColor: AppData.avatarColor,
              backgroundImage: user?.photoUrl != null 
      ? NetworkImage(user!.photoUrl!) 
      : null,
              child: user?.photoUrl == null
      ? const Icon(Icons.person, size: 55, color: Colors.white)
      : null,
            ),
            const SizedBox(height: 12),
            Text(
              user?.name.toUpperCase() ?? "GUEST",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppData.primaryColor,
              ),
            ),
            const SizedBox(height: 25),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 25),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: AppData.accentColor, width: 2),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
                color: AppData.backgroundColor,
              ),
              child: Column(
                children: [
                  const Text(
                    "SETTINGS",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: "App Settings",
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Notifications",
                            style: TextStyle(fontSize: 15),
                          ),
                          Switch(
                            value: isNotificationsEnabled,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppData.primaryColor,
                            onChanged: (val) =>
                                setState(() => isNotificationsEnabled = val),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: "Account",
                    children: [_buildSettingsRow("Account summary")],
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      await GoogleSignIn().signOut();

                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppData.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "LOGOUT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsRow(String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black87),
      ],
    );
  }
}
