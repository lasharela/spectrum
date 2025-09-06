import 'package:flutter/material.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;
  final IconData icon;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    required this.icon,
  });
}
