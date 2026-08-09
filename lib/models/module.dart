import 'package:hive/hive.dart';

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

  Module({
    required this.id,
    required this.title,
    this.parentId,
    this.lastOpenedAt,
    this.iconName = 'folder',
    this.description = '',
  });

  DateTime getLastOpenedAt() =>
      lastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> updateLastOpenedAt() async {
    lastOpenedAt = DateTime.now();
    await save();
  }
}
