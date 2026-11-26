import 'package:hive/hive.dart';

import 'project_task.dart';

part 'module.g.dart';

/// A Module represents a top-level guide/topic (e.g. "C Basics") or a
/// submodule when [parentId] is set. Submodules are just other [Module]
/// records whose [parentId] points at their parent's [id].
@HiveType(typeId: 0)
class Module extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final String? parentId;

  @HiveField(4)
  DateTime? lastOpenedAt;

  @HiveField(5)
  String iconName;

  @HiveField(6)
  String description;

  // defaultValue below matters for records saved before these fields
  // existed: Hive's generated reader does `fields[n] as bool` etc., which
  // throws on a genuinely missing (null) field unless a defaultValue is
  // given - it's not just the Dart constructor default used in code.
  @HiveField(7, defaultValue: false)
  bool isProject;

  @HiveField(8, defaultValue: 'in_progress')
  String status;

  @HiveField(9)
  String? repoUrl;

  @HiveField(10)
  DateTime? deadline;

  @HiveField(11, defaultValue: <ProjectTask>[])
  List<ProjectTask> tasks;

  /// When this module's own fields (title, description, status, tasks, ...)
  /// were last changed - distinct from [lastOpenedAt], which tracks viewing
  /// it. Null for modules saved before this field existed, or that have
  /// never gone through [database_helper.DatabaseHelper.updateModule].
  @HiveField(12)
  DateTime? updatedAt;

  Module({
    required this.id,
    required this.title,
    this.parentId,
    this.lastOpenedAt,
    this.iconName = 'folder',
    this.description = '',
    this.isProject = false,
    this.status = 'in_progress',
    this.repoUrl,
    this.deadline,
    List<ProjectTask>? tasks,
    this.updatedAt,
  }) : tasks = tasks ?? [];

  /// Percentage of [tasks] marked done, or null when there are no tasks
  /// (so callers can distinguish "no checklist" from "0% complete").
  int? get taskCompletionPercent {
    if (tasks.isEmpty) return null;
    final doneCount = tasks.where((t) => t.done).length;
    return ((doneCount / tasks.length) * 100).round();
  }

  DateTime getLastOpenedAt() =>
      lastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> updateLastOpenedAt() async {
    lastOpenedAt = DateTime.now();
    await save();
  }

  /// When this module was last edited, for activity/recency purposes.
  /// Falls back to the epoch for modules that have never been edited since
  /// [updatedAt] started being tracked.
  DateTime getUpdatedAt() =>
      updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}
