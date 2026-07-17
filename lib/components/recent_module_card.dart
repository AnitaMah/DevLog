import 'package:flutter/material.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/helpers/icon_helper.dart';

/// Віджет для відображення картки недавнього модуля.
class RecentModuleCard extends StatelessWidget {
  final Module module;
  final VoidCallback onTap;

  const RecentModuleCard({
    super.key,
    required this.module,
    required this.onTap,
  });

  String _formatTimeAgo(DateTime lastOpened) {
    final now = DateTime.now();
    final difference = now.difference(lastOpened);

    if (difference.inMinutes < 60) return "${difference.inMinutes} min ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";
    return "${(difference.inDays / 7).floor()}w ago";
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(module.getLastOpenedAt());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240, // Зменшено ширину для компактності
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground, // Темний фон картки[cite: 7, 16]
          borderRadius: BorderRadius.circular(8), // Строгіші кути
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconHelper.getFaIcon(
                  module.iconName,
                  color: AppColors.accentPurple,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    module.title,
                    style: AppTextStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              module.description.isNotEmpty ? module.description : "No description",
              style: AppTextStyles.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeAgo, style: AppTextStyles.smallText),
                const Icon(Icons.bookmark_border, color: Colors.white24, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}