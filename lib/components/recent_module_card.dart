import 'package:flutter/material.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/helpers/icon_helper.dart';

/// Віджет для відображення картки недавнього модуля.
/// Використовується у секції "Continue where you left off".
class RecentModuleCard extends StatelessWidget {
  final Module module;
  final VoidCallback onTap;

  const RecentModuleCard({
    super.key,
    required this.module,
    required this.onTap,
  });

  /// Форматує час у зручний для користувача вигляд (наприклад, "5 min ago").
  String _formatTimeAgo(DateTime lastOpened) {
    final now = DateTime.now();
    final difference = now.difference(lastOpened);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago";
    } else {
      return "${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() != 1 ? 's' : ''} ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastOpened = module.getLastOpenedAt();
    final timeAgo = _formatTimeAgo(lastOpened);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Іконка та заголовок
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconHelper.getFaIcon(
                    module.iconName,
                    color: AppColors.accentPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: AppTextStyles.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      module.description.isNotEmpty
                          ? module.description
                          : "No description",
                      style: AppTextStyles.cardSubtitle.copyWith(
                        color: AppColors.accentPurple,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Опис модуля
            Text(
              module.description,
              style: AppTextStyles.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Час останнього відкриття та іконка закладки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeAgo, style: AppTextStyles.smallText),
                const Icon(
                  Icons.bookmark_border,
                  color: Colors.white38,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}