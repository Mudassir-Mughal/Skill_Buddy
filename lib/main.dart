import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'Screens/Splash.dart';
import 'Screens/theme.dart';
import 'Service/MatchService.dart';
import 'firebase_options.dart';

// 🔑 Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize match service (if still needed)
  MatchService matchService = MatchService();
  await matchService.findMatches();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppColors.lightTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: SplashScreen(),
    );
  }
}