import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeaderLogoSection extends StatelessWidget {
  const HeaderLogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, 
        vertical: AppSpacing.xl
      ),
      child: Row(
        children: [
          // Фірмовий квадрат "42"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentPurple,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Text(
              "42",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900, // Жирний напис
                fontSize: 18,
                fontFamily: 'monospace', // Стиль, що нагадує термінал
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Текстова частина
          const Text(
            "Guides",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}