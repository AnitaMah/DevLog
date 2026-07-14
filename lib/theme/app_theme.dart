import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color sidebarBackground = Color(0xFF161618);
  static const Color cardBackground = Color(0xFF1E1E1E); // Використовуйте замість .card [8, 9]
  static const Color textWhite = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accentPurple = Color(0xFF7C4DFF);
}

class AppTextStyles {
  static const TextStyle header = TextStyle(color: AppColors.textWhite, fontSize: 24, fontWeight: FontWeight.bold);
  static const TextStyle cardTitle = TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold);
  static const TextStyle cardSubtitle = TextStyle(color: AppColors.textSecondary, fontSize: 12);
  static const TextStyle body = TextStyle(color: AppColors.textSecondary, fontSize: 14);
}