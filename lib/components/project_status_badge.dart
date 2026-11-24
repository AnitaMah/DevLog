import 'package:flutter/material.dart';

import 'package:dev_log/helpers/project_status.dart';

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
