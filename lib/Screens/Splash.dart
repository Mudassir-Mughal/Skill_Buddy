import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Service/api_service.dart';
import 'setprofile.dart';
import 'AppidentityIcon.dart';
import 'StudentHome.dart';
import 'home.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Simple timer for navigation
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateNext(); // Your existing navigation function
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Replace _navigateNext with MongoDB logic, no shared_preferences
  void _navigateNext() async {
    // Restore userId from persistent storage
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId != null && userId.isNotEmpty) {
      ApiService.currentUserId = userId;
      final userData = await ApiService.getUserProfile(userId);
      if (userData != null) {
        final role = userData['role'];
        final profileSet = userData['profileSet'] ?? false;
        if (profileSet == true) {
          if (role == 'Student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentHomePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage(userId: userId)),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SetProfilePage(isFromSignUp: false, userId: userId)),
          );
        }
        return;
      }
    }
    // If not logged in or user not found, go to login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C63FF),
              const Color(0xFF4F5EE2),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Enhanced Icon Stack
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer decorative circle
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                          ),
                          // Middle circle
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ripple effect circles
                                ...List.generate(3, (index) {
                                  return Positioned(
                                    left: 20.0 - (index * 5),
                                    top: 20.0 - (index * 5),
                                    child: Container(
                                      width: 80 + (index * 10),
                                      height: 80 + (index * 10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2 - (index * 0.05)),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                // Main icons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Transform.rotate(
                                      angle: -0.2,
                                      child: const Icon(
                                        Icons.school_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Transform.rotate(
                                      angle: 0.2,
                                      child: const Icon(
                                        Icons.handshake_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // App Name with Gradient
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.9),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: const Text(
                          "Skill Buddy",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tagline
                      Text(
                        "Master · Share · Grow",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Time and User Info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),

                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }}