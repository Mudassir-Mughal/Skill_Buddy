import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF6C63FF); // Modern indigo
  static const _secondaryColor = Color(0xFF32B5FF); // Vibrant blue
  static const _accentColor = Color(0xFFFF6584); // Coral pink
  static const background = Color(0xFFF8F9FE); // Soft background
  static const _surfaceColor = Colors.white;
  static const white = Colors.white;
  static const _errorColor = Color(0xFFFF4B55);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.grey;
  static const card = Colors.white;
  static const text = Colors.black87;
  static const Color iconBg = Color(0xFFE6E9F8);
  static const Color accent = Color(0xFF9575CD);
  static const buttonText = Colors.white;
  static const Color sentMessage = Color(0xFFE1BEE7); // light purple
  static const Color receivedMessage = Colors.white;
  static const Color chatMe = Color(0xFF6C63FF); // Bubble for current user
  static const Color chatPeer = Color(0xFFE9E9F3); // Bubble for peer


  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      secondary: _secondaryColor,
      background: background,
      surface: _surfaceColor,
      error: _errorColor,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        letterSpacing: 0.25,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _surfaceColor,
      elevation: 8,
      height: 65,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primary,
          );
        }
        return GoogleFonts.inter(
          fontSize: 12,
          color: Colors.grey[600],
        );
      }),
    ),
  );
}
