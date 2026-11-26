import 'package:hive/hive.dart';

part 'note.g.dart';

/// A single note that belongs to a [Module] (via [moduleId]).
@HiveType(typeId: 2)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String moduleId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String content;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  final List<String> tags;

  /// Which AI a chat-import note came from (an [AiSource.storageValue]), or
  /// null for a regular note. Stored as a plain string rather than tying
  /// the Hive schema to the AiSource enum, so the enum can change freely.
  @HiveField(7)
  String? aiSource;

  Note({
    required this.id,
    required this.moduleId,
    required this.title,
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    this.aiSource,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];

  Future<void> update({
    String? title,
    String? content,
    List<String>? tags,
    String? aiSource,
    String? moduleId,
  }) async {
    if (title != null) this.title = title;
    if (content != null) this.content = content;
    if (tags != null) {
      this.tags
        ..clear()
        ..addAll(tags);
    }
    if (aiSource != null) this.aiSource = aiSource;
    if (moduleId != null) this.moduleId = moduleId;
    updatedAt = DateTime.now();
    await save();
  }
}
