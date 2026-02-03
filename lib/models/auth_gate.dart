import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seriestime/login_screen.dart';
import 'package:seriestime/main.dart';
import 'package:seriestime/models/appdata.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Ascolta i cambiamenti di stato dell'utente (Loggato / Non loggato)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // 1. Se Firebase sta ancora controllando lo stato iniziale
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black, // O AppData.backgroundColor
            body: Center(child: CircularProgressIndicator(color: AppData.primaryColor)),
          );
        }

        // 2. Se l'utente è Loggato (snapshot ha dati)
        if (snapshot.hasData) {
          // Dobbiamo caricare i dati Firestore (Serie, Badge) prima di mostrare la Home
          // altrimenti la ProfileScreen e MySeriesScreen sarebbero vuote.
          return FutureBuilder(
            future: AppData.initializeData(), // Carica i dati
            builder: (context, dataSnapshot) {
              if (dataSnapshot.connectionState == ConnectionState.done) {
                // Dati caricati -> Vai all'App
                return const MainWrapper();
              } else {
                // Sta caricando i dati da Firestore -> Loading Screen
                return const Scaffold(
                  backgroundColor: AppData.backgroundColor,
                  body: Center(child: CircularProgressIndicator(color: AppData.primaryColor)),
                );
              }
            },
          );
        }

        // 3. Se l'utente NON è loggato -> Mostra LoginScreen
        return const LoginScreen();
      },
    );
  }
}