import 'package:hive/hive.dart';

part 'module.g.dart';

@HiveType(typeId: 0)
class Module extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  int notesCount;

  @HiveField(4)
  String iconName;

  @HiveField(5)
  String? parentId;

  @HiveField(6)
  String? filePath;

  @HiveField(7)
  double progress;

  // Зберігаємо саме як String, як і було
  @HiveField(8)
  String lastOpenedAt;

  Module({
    required this.id,
    required this.title,
    this.description = '',
    this.notesCount = 0,
    this.iconName = 'code',
    this.parentId,
    this.filePath,
    this.progress = 0.0,
    String? lastOpenedAt, // Змінено: приймаємо String, а не DateTime
  }) : lastOpenedAt = lastOpenedAt ?? DateTime.now().toIso8601String();

  DateTime getLastOpenedAt() {
    return DateTime.parse(lastOpenedAt);
  }

  void updateLastOpenedAt() {
    lastOpenedAt = DateTime.now().toIso8601String();
    save();
  }
}