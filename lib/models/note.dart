/// A single note that belongs to a [Module] (via [moduleId]).
///
/// This is the first step of adding real notes: just the plain data shape.
/// Hive persistence (the generated adapter, storage box, etc.) comes in a
/// later step — this class isn't wired to storage yet.
class Note {
  final String id;
  final String moduleId;
  String title;
  String content;
  final DateTime createdAt;
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

  void update({String? title, String? content}) {
    if (title != null) this.title = title;
    if (content != null) this.content = content;
    updatedAt = DateTime.now();
  }
}
