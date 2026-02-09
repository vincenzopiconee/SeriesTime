import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seriestime/screens/login_screen.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:seriestime/screens/main_wrapper_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black, 
            body: Center(child: CircularProgressIndicator(color: AppData.primaryColor)),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder(
            future: AppData.initializeData(),
            builder: (context, dataSnapshot) {
              if (dataSnapshot.connectionState == ConnectionState.done) {
                return const MainWrapper();
              } else {
                return const Scaffold(
                  backgroundColor: AppData.backgroundColor,
                  body: Center(child: CircularProgressIndicator(color: AppData.primaryColor)),
                );
              }
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}