import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Screens/Splash.dart';
import 'Screens/home.dart';
import 'Screens/login.dart';
import 'Screens/theme.dart';
import 'firebase_options.dart'; // ✅ Import firebase_options

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ✅ Proper initialization
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppColors.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // ✅ Keep your splash screen
    );
  }
}
