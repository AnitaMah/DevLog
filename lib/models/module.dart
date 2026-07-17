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
  String? parentId; // Якщо null — це головний модуль

  @HiveField(6)
  String? filePath;

  @HiveField(7)
  double progress;

  @HiveField(8)
  String lastOpenedAt;

  // Нове поле для зручного зберігання зв'язків
  @HiveField(9)
  List<String> subModuleIds;

  Module({
    required this.id,
    required this.title,
    this.description = '',
    this.notesCount = 0,
    this.iconName = 'code',
    this.parentId,
    this.filePath,
    this.progress = 0.0,
    String? lastOpenedAt,
    List<String>? subModuleIds,
  })  : lastOpenedAt = lastOpenedAt ?? DateTime.now().toIso8601String(),
        subModuleIds = subModuleIds ?? [];

  // Метод для додавання підмодуля
  void addSubModule(String id) {
    if (!subModuleIds.contains(id)) {
      subModuleIds.add(id);
      save();
    }
  }

  DateTime getLastOpenedAt() {
    return DateTime.parse(lastOpenedAt);
  }

  void updateLastOpenedAt() {
    lastOpenedAt = DateTime.now().toIso8601String();
    save();
  }
}
