import 'package:flutter/material.dart';

class AppColors {
  // New vibrant color palette from provided image
  static const Color primary = Color(0xFF6FCFEB); // Cyan/Light Blue
  static const Color secondary = Color(0xFF8FD14F); // Green
  static const Color tertiary = Color(0xFFFEE761); // Yellow
  static const Color quaternary = Color(0xFFFF6B35); // Orange/Red

  // Additional accent colors
  static const Color accent1 = Color(0xFFFFBE4F); // Light Orange
  static const Color accent2 = Color(0xFF6FCFEB); // Cyan
  static const Color accent3 = Color(0xFF8FD14F); // Green
  static const Color accent4 = Color(0xFFFEE761); // Yellow

  // Neutral backgrounds
  static const Color background = Color(0xFFF8F9FA); // Light grey
  static const Color surface = Colors.white;
  
  // Status colors
  static const Color error = Color(0xFFFF6B35); // Orange/Red
  static const Color success = Color(0xFF8FD14F); // Green
  static const Color warning = Color(0xFFFEE761); // Yellow
  static const Color info = Color(0xFF6FCFEB); // Cyan

  // Text colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textDisabled = Color(0xFFBDC3C7);

  // UI elements
  static const Color divider = Color(0xFFECF0F1);
  static const Color disabled = Color(0xFFE8EAED);
  static const Color overlay = Color(0x1F6FCFEB); // Light blue overlay
  
  // Card styling
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE8EAED);
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: const Offset(0, 2),
  );
}
