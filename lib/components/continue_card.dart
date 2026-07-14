import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ContinueCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeAgo; // Додайте це поле

  const ContinueCard({
    super.key, 
    required this.title, 
    required this.subtitle,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground, // Виправлено ім'я
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.cardTitle),
          const SizedBox(height: 8),
          Text(subtitle, style: AppStyles.body),
          const SizedBox(height: 8),
          Text(timeAgo, style: AppStyles.smallText), // Використання
        ],
      ),
    );
  }
}