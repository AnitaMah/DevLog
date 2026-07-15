import 'package:flutter/material.dart';
import 'package:dev_log/theme/app_theme.dart';

class ContinueCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description; // Додано опис для відповідності макету [1]
  final String timeAgo;

  const ContinueCard({
    super.key, 
    required this.title, 
    required this.subtitle, 
    required this.description,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.code, color: AppColors.accentPurple, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  Text(subtitle, style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.accentPurple)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(description, style: AppTextStyles.body, maxLines: 2),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(timeAgo, style: AppTextStyles.smallText),
              const Icon(Icons.bookmark_border, color: Colors.white38, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}