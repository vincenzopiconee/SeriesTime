import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seriestime/firebase_options.dart';
import 'package:seriestime/widgets/auth_gate.dart';
import 'models/appdata.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.top]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SeriesTime',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppData.primaryColor),
        useMaterial3: true,
        textTheme: GoogleFonts.firaSansCondensedTextTheme(),
        scaffoldBackgroundColor: AppData.backgroundColor,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }
}