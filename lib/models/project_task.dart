import 'package:hive/hive.dart';

part 'project_task.g.dart';

/// A single checklist item on a project [Module]. Stored inline inside the
/// owning Module's record (not its own Hive box), so this does not extend
/// [HiveObject].
@HiveType(typeId: 3)
class ProjectTask {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool done;

  @HiveField(2)
  DateTime? dueDate;

  ProjectTask({required this.title, this.done = false, this.dueDate});
}
