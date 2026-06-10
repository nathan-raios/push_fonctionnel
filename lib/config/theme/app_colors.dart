// lib/config/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4B44CC);
  static const Color primaryLight = Color(0xFF9D97FF);
  
  // Secondary
  static const Color secondary = Color(0xFFFF6584);
  static const Color accent = Color(0xFFFFD166);
  
  // Background
  static const Color background = Color(0xFF0F0E17);
  static const Color backgroundCard = Color(0xFF1A1A2E);
  static const Color backgroundLight = Color(0xFF16213E);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textHint = Color(0xFF6B6B80);
  
  // Categories Colors
  static const Color concert = Color(0xFFFF6B6B);
  static const Color soiree = Color(0xFF9B59B6);
  static const Color rencontre = Color(0xFF3498DB);
  static const Color jeux = Color(0xFF2ECC71);
  static const Color sport = Color(0xFFE67E22);
  static const Color culture = Color(0xFFE74C3C);
  
  // Status
  static const Color success = Color(0xFF06D6A0);
  static const Color error = Color(0xFFEF476F);
  static const Color warning = Color(0xFFFFD166);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [background, backgroundLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}