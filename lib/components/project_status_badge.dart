import 'package:flutter/material.dart';

import 'package:dev_log/helpers/project_status.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Small colored badge showing a project [Module]'s status. Used anywhere
/// a project module is listed (grid/list views, submodule rows, recent
/// cards) so projects read as visually distinct from plain guide modules.
class ProjectStatusBadge extends StatelessWidget {
  final String status;

  /// Checklist completion, 0-100. Pass [Module.taskCompletionPercent]; null
  /// (no checklist) hides the percentage instead of showing "0%".
  final int? completionPercent;

  const ProjectStatusBadge({super.key, required this.status, this.completionPercent});

  @override
  Widget build(BuildContext context) {
    final color = projectStatusColor(status);
    final label = completionPercent == null
        ? projectStatusLabel(status)
        : '${projectStatusLabel(status)} · $completionPercent%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Mint pill showing a project [Module]'s checklist completion - the
/// Terminal Dark mockup's project-card/detail-header "60%" badge.
class ProjectPercentBadge extends StatelessWidget {
  final int percent;
  const ProjectPercentBadge({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentMutedBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$percent%',
        style: AppTextStyles.mono.copyWith(
          color: AppColors.accentMutedFg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Amber pill showing a project [Module]'s deadline - the mockup's
/// detail-header "due Dec 15" badge.
class ProjectDeadlineBadge extends StatelessWidget {
  final DateTime deadline;
  const ProjectDeadlineBadge({super.key, required this.deadline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'due ${formatDeadline(deadline)}',
        style: AppTextStyles.mono.copyWith(
          color: AppColors.amber,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Thin rounded teal-on-dark completion bar for a project [Module]'s
/// checklist - shared by [ProjectHeroCard] and the project detail header
/// so both match the mockup's progress-bar styling exactly.
class ProjectProgressBar extends StatelessWidget {
  final int percent;
  const ProjectProgressBar({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 6,
        color: AppColors.cardBorder,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: (percent / 100).clamp(0.0, 1.0),
          child: Container(color: AppColors.accent),
        ),
      ),
    );
  }
}
