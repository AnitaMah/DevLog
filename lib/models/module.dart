import 'package:hive/hive.dart';

part 'module.g.dart'; // Цей файл має з'явитися після генерації

@HiveType(typeId: 0) // typeId має бути унікальним (0, 1, 2...)
class Module extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final int notesCount;

  Module({required this.title, required this.notesCount});
}