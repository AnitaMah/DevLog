import 'package:hive/hive.dart';

part 'module.g.dart'; // Цей файл має з'явитися після генерації

@HiveType(typeId: 0)
class Module extends HiveObject {
  @HiveField(0)
  final String id;  // Add unique ID

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;  // Add description

  @HiveField(3)
  final int notesCount;

  @HiveField(4)
  final DateTime createdAt;  // Add timestamp

  Module({
    required this.id,
    required this.title,
    required this.description,
    required this.notesCount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
