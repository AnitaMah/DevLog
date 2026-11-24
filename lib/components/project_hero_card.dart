import 'package:flutter/material.dart';

import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/helpers/project_status.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/screens/module_details_screen.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Solid accent-filled hero card for a project [Module], used in
/// [ProjectsSection]'s dashboard grid. Distinct from [ModuleTile] (which
/// stays a plain dark row, used for submodules) since only the dashboard's
/// "active work" entry points - Projects and "Continue where you left off"
/// - get the bold solid-fill treatment.
class ProjectHeroCard extends StatelessWidget {
  final Module module;

  const ProjectHeroCard({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final doneCount = module.tasks.where((t) => t.done).length;

    return GestureDetector(
      onTap: () {
        module.updateLastOpenedAt();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ModuleDetailsScreen(module: module)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentOnColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: IconHelper.getFaIcon(module.iconName, color: AppColors.accentOnColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    module.title,
                    style: const TextStyle(color: AppColors.accentOnColor, fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentOnColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    projectStatusLabel(module.status),
                    style: const TextStyle(color: AppColors.accentOnColor, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                if (module.tasks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$doneCount/${module.tasks.length} tasks · ${module.taskCompletionPercent}%',
                    style: TextStyle(color: AppColors.accentOnColor.withValues(alpha: 0.8), fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
