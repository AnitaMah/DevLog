import 'package:flutter/material.dart';

import 'package:dev_log/components/project_status_badge.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/helpers/project_status.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/screens/module_details_screen.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Glass project card for [ProjectsScreen]'s grid, matching the Terminal
/// Dark + Spatial mockup: icon/title row, completion badge, progress bar,
/// and a task-count/deadline footer.
class ProjectHeroCard extends StatelessWidget {
  final Module module;

  const ProjectHeroCard({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final percent = module.taskCompletionPercent;
    final doneCount = module.tasks.where((t) => t.done).length;
    final (bg, fg) = AppColors.moduleColorFor(module.title);
    final deadline = module.deadline;

    return GlassPanel(
      child: InkWell(
        onTap: () {
          module.updateLastOpenedAt();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ModuleDetailsScreen(module: module)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: IconHelper.getFaIcon(module.iconName, color: fg, size: 14),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      module.title,
                      style: AppTextStyles.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (percent != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ProjectPercentBadge(percent: percent),
                  ],
                ],
              ),
              if (percent != null) ...[
                const SizedBox(height: AppSpacing.md),
                ProjectProgressBar(percent: percent),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    module.tasks.isEmpty
                        ? projectStatusLabel(module.status)
                        : '$doneCount/${module.tasks.length} done',
                    style: AppTextStyles.mono.copyWith(fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    deadline == null ? 'No deadline' : formatDeadline(deadline),
                    style: AppTextStyles.mono.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
