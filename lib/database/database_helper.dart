import 'package:hive_flutter/hive_flutter.dart';
import '../models/module.dart';
import '../models/user_model.dart';
import '../models/note.dart';

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

  // --- Files ---
  static Future<void> addFileToModule(String moduleId, String fileName) async {
    final module = _modules.values.firstWhere((m) => m.id == moduleId);
    module.files.add(fileName);
    await module.save();
  }

  // --- Notes ---
  static Box<Note> get _notes => Hive.box<Note>(_notesBox);

  static List<Note> getAllNotes() => _notes.values.toList();

  static List<Note> getNotesForModule(String moduleId) =>
      _notes.values.where((n) => n.moduleId == moduleId).toList();

  static Future<Note> addNote(String moduleId, {String title = 'Untitled note', String content = ''}) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      moduleId: moduleId,
      title: title,
      content: content,
    );
    await _notes.add(note);
    return note;
  }

  static Future<void> updateNote(Note note, {String? title, String? content}) async {
    await note.update(title: title, content: content);
  }

  static Future<void> deleteNote(String noteId) async {
    final note = _notes.values.firstWhere((n) => n.id == noteId);
    await note.delete();
  }
}
