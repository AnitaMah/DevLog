import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import '../models/module.dart';
import '../models/user_model.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class DatabaseHelper {
  static const String _modulesBox = 'modules';
  static const String _userBox = 'userBox';
  static const String _notesBox = 'notes';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ModuleAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(NoteAdapter());
    await Hive.openBox<Module>(_modulesBox);
    await Hive.openBox<UserModel>(_userBox);
    await Hive.openBox<Note>(_notesBox);

    // Restore the saved light/dark preference, if any.
    if (_users.isNotEmpty) {
      AppColors.setDark(_users.getAt(0)!.isDarkMode);
    }
  }

  // --- User / preferences ---
  static Box<UserModel> get _users => Hive.box<UserModel>(_userBox);

  static Future<void> saveThemePreference(bool isDark) async {
    if (_users.isEmpty) {
      await _users.add(UserModel(name: "User", email: "", isDarkMode: isDark));
    } else {
      final user = _users.getAt(0)!;
      user.isDarkMode = isDark;
      await user.save();
    }
  }

  // --- Modules ---
  static Box<Module> get _modules => Hive.box<Module>(_modulesBox);

  static List<Module> getAllModules() => _modules.values.toList();

  static List<Module> getRootModules() =>
      _modules.values.where((m) => m.parentId == null).toList();

  /// Submodules are just [Module]s whose parentId points at [parentId].
  static List<Module> getSubmodules(String parentId) =>
      _modules.values.where((m) => m.parentId == parentId).toList();

  static Future<void> addModule(Module module) async {
    await _modules.add(module);
  }

  static Future<void> updateModule(Module module) async {
    await module.save();
  }

  static Future<void> deleteModule(String moduleId) async {
    // Delete the module along with any submodules that point at it,
    // and any notes that belong to it.
    final children = getSubmodules(moduleId);
    for (final child in children) {
      await deleteModule(child.id);
    }
    for (final note in getNotesForModule(moduleId)) {
      await note.delete();
    }
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    await module.delete();
  }

  // --- Notes ---
  static Box<Note> get _notes => Hive.box<Note>(_notesBox);

  static List<Note> getAllNotes() => _notes.values.toList();

  static List<Note> getNotesForModule(String moduleId) =>
      _notes.values.where((n) => n.moduleId == moduleId).toList();

  static int getNotesCountForModule(String moduleId) =>
      _notes.values.where((n) => n.moduleId == moduleId).length;

  static Future<Note> addNote(
    String moduleId, {
    String title = 'Untitled note',
    String content = '',
    List<String>? tags,
  }) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      moduleId: moduleId,
      title: title,
      content: content,
      tags: tags,
    );
    await _notes.add(note);
    return note;
  }

  static Future<void> updateNote(Note note,
      {String? title, String? content, List<String>? tags}) async {
    await note.update(title: title, content: content, tags: tags);
  }

  static Future<void> deleteNote(String noteId) async {
    final note = _notes.values.firstWhere((n) => n.id == noteId);
    await note.delete();
  }

  /// All distinct tags across every note, with how many notes use each,
  /// sorted by popularity (most-used first).
  static List<MapEntry<String, int>> getAllTagsWithCounts() {
    final counts = <String, int>{};
    for (final note in _notes.values) {
      for (final tag in note.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  static List<Note> getNotesByTag(String tag) =>
      _notes.values.where((n) => n.tags.contains(tag)).toList();

  // --- Export / Import ---

  /// A JSON-serializable snapshot of every module and note.
  static Map<String, dynamic> exportData() {
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'modules': _modules.values
          .map((m) => {
                'id': m.id,
                'title': m.title,
                'parentId': m.parentId,
                'lastOpenedAt': m.lastOpenedAt?.toIso8601String(),
                'iconName': m.iconName,
                'description': m.description,
              })
          .toList(),
      'notes': _notes.values
          .map((n) => {
                'id': n.id,
                'moduleId': n.moduleId,
                'title': n.title,
                'content': n.content,
                'createdAt': n.createdAt.toIso8601String(),
                'updatedAt': n.updatedAt.toIso8601String(),
                'tags': n.tags,
              })
          .toList(),
    };
  }

  static String exportDataAsJson() =>
      const JsonEncoder.withIndent('  ').convert(exportData());

  /// Replaces every module and note with the contents of a previously
  /// exported JSON string. Throws a [FormatException] if [jsonStr] doesn't
  /// look like a 42 Guides export.
  static Future<void> importDataFromJson(String jsonStr) async {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic> ||
        decoded['modules'] is! List ||
        decoded['notes'] is! List) {
      throw const FormatException('Not a valid 42 Guides export file.');
    }

    final modulesJson = decoded['modules'] as List;
    final notesJson = decoded['notes'] as List;

    await _modules.clear();
    await _notes.clear();

    for (final entry in modulesJson) {
      final map = entry as Map<String, dynamic>;
      await _modules.add(Module(
        id: map['id'] as String,
        title: map['title'] as String,
        parentId: map['parentId'] as String?,
        lastOpenedAt: map['lastOpenedAt'] != null
            ? DateTime.parse(map['lastOpenedAt'] as String)
            : null,
        iconName: map['iconName'] as String? ?? 'folder',
        description: map['description'] as String? ?? '',
      ));
    }

    for (final entry in notesJson) {
      final map = entry as Map<String, dynamic>;
      await _notes.add(Note(
        id: map['id'] as String,
        moduleId: map['moduleId'] as String,
        title: map['title'] as String,
        content: map['content'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
        tags: (map['tags'] as List?)?.map((t) => t.toString()).toList(),
      ));
    }
  }

  // --- Danger zone ---

  /// Deletes every module and note. Leaves the user's profile and theme
  /// preference untouched.
  static Future<void> clearAllData() async {
    await _modules.clear();
    await _notes.clear();
  }
}
