import 'package:flutter/material.dart';
import 'config.dart';

import 'Screens/Splash.dart';
import 'Screens/theme.dart';
import 'Service/MatchService.dart';

// 🔑 Global navig
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No Firebase initialization needed
  // Set up MongoDB backend connection via your backend API only

  MatchService matchService = MatchService(baseUrl: baseUrl, currentUserId: '');
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