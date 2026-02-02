import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color primaryBlue = Color(0xFFA2D2FF);
  static const Color alertRed = Color(0xFFFF869E);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textLight = Color(0xFF636E72);
  
  // Gradient Background
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEBF2FA), Color(0xFFFFFFFF)],
  );
  
  // Player Progress Gradient
  static const LinearGradient progressGradient = LinearGradient(
    colors: [Color(0xFFA2D2FF), Color(0xFFBDE0FE)],
  );
  
  // Neumorphic Shadows
  static List<BoxShadow> get neumorphicShadow => [
    BoxShadow(
      color: Colors.white.withOpacity(0.7),
      offset: const Offset(-4, -4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFFB0C4DE).withOpacity(0.5),
      offset: const Offset(4, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  // Inner Glow Shadow
  static List<BoxShadow> get innerGlow => [
    BoxShadow(
      color: primaryBlue.withOpacity(0.3),
      offset: const Offset(0, 0),
      blurRadius: 20,
      spreadRadius: -5,
    ),
  ];
  
  // Border Radius
  static const double borderRadius = 30.0;
  static const double streamRadius = 25.0;
  
  // Glassmorphism Surface
  static Color get glassSurface => surfaceColor.withOpacity(0.8);
}

