import 'package:flutter/material.dart';

class AppColors {
  // New color palette from design system
  static const Color primary = Color(0xFF262CD9); // Blue
  static const Color secondary = Color(0xFFC8A9F2); // Light Purple
  static const Color tertiary = Color(0xFF6FC2FF); // Light Blue
  static const Color quaternary = Color(0xFF1E9A64); // Green
  
  // Additional colors
  static const Color accent1 = Color(0xFFD8032C); // Red
  static const Color accent2 = Color(0xFFF2A100); // Yellow/Orange
  static const Color darkGray = Color(0xFF383838); // Dark Gray
  
  // Neutral backgrounds
  static const Color background = Color(0xFFF4EFEA); // Light beige
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFFFF3E0); // Light cream
  
  // Status colors
  static const Color error = Color(0xFFD8032C); // Red
  static const Color success = Color(0xFF1E9A64); // Green
  static const Color warning = Color(0xFFF2A100); // Yellow
  static const Color info = Color(0xFF6FC2FF); // Light Blue

  // Text colors
  static const Color textPrimary = Color(0xFF383838); // Dark gray
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textDisabled = Color(0xFFBDC3C7);
  static const Color textOnPrimary = Colors.white;

  // UI elements
  static const Color divider = Color(0xFFE8EAED);
  static const Color disabled = Color(0xFFE8EAED);
  static const Color overlay = Color(0x1F6FC2FF); // Light blue overlay
  static const Color blackBorder = Color(0xFF383838); // For card borders
  
  // Card styling - Simple and clean
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE8EAED); // Light border
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
  
  // Simple card border style
  static BoxBorder cardBorderStyle = Border.all(
    color: cardBorder,
    width: 1,
  );
}
