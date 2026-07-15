import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F0F11); // Глибокий темний фон [1]
  static const Color sidebarBackground = Color(0xFF161618);
  static const Color cardBackground = Color(0xFF1E1E21); // Колір карток [1, 5]
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color textWhite = Colors.white;
  static const Color textSecondary = Colors.white70;
}

class AppTextStyles {
  static const TextStyle header = TextStyle(
    color: AppColors.textWhite, fontSize: 24, fontWeight: FontWeight.bold);
  
  static const TextStyle title = TextStyle(
    color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.w600);

  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold);

  static const TextStyle cardSubtitle = TextStyle(
    color: AppColors.textSecondary, fontSize: 12);
  
  static const TextStyle body = TextStyle(
    color: AppColors.textSecondary, fontSize: 13);

  static const TextStyle smallText = TextStyle(
    color: Colors.white38, fontSize: 11);
}

