import 'package:flutter/material.dart';

class AppColors {
  // Основна палітра
  static const Color background = Color(0xFF0F0F11);
  static const Color sidebarBackground = Color(0xFF161618);
  static const Color cardBackground = Color(0xFF1E1E21);
  
  // Акцентні кольори
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentPurpleLight = Color(0xFF9575CD);
  
  // Текст та елементи
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textDisabled = Colors.white30;
  static const Color divider = Colors.white10;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppRadius {
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
}

class AppTextStyles {
  static const TextStyle header = TextStyle(
    color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold);
  
  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600);

  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold);

  static const TextStyle cardSubtitle = TextStyle(
    color: AppColors.textSecondary, fontSize: 12);
  
  static const TextStyle body = TextStyle(
    color: AppColors.textSecondary, fontSize: 13, height: 1.5);

  static const TextStyle smallText = TextStyle(
    color: AppColors.textDisabled, fontSize: 11);
}