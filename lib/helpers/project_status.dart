import 'package:flutter/material.dart';

/// Status options for a project [Module], in display order. Stored as-is
/// on [Module.status] (a plain string, not a Hive enum) - shared here so
/// the editor dialog and every place a project is displayed agree on the
/// same labels/colors instead of each defining their own.
const projectStatusLabels = <String, String>{
  'planning': 'Planning',
  'in_progress': 'In Progress',
  'done': 'Done',
  'archived': 'Archived',
};

const projectStatusColors = <String, Color>{
  'planning': Color(0xFF29B6F6),
  'in_progress': Color(0xFF7C4DFF),
  'done': Color(0xFF4CAF93),
  'archived': Color(0xFF9A9AA2),
};

String projectStatusLabel(String status) => projectStatusLabels[status] ?? status;

Color projectStatusColor(String status) =>
    projectStatusColors[status] ?? projectStatusColors['in_progress']!;

const _monthAbbrev = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Dec 15" - short form used wherever a project [Module.deadline] is shown
/// next to other compact metadata (task counts, status labels).
String formatDeadline(DateTime date) => '${_monthAbbrev[date.month - 1]} ${date.day}';
