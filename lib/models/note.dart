import 'package:hive/hive.dart';

part 'note.g.dart';

/// A single note that belongs to a [Module] (via [moduleId]).
@HiveType(typeId: 2)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String moduleId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String content;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  Note({
    required this.id,
    required this.moduleId,
    required this.title,
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Future<void> update({String? title, String? content}) async {
    if (title != null) this.title = title;
    if (content != null) this.content = content;
    updatedAt = DateTime.now();
    await save();
  }
}
