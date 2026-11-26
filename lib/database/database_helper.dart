import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../helpers/id_generator.dart';
import '../models/activity_item.dart';
import '../models/module.dart';
import '../models/project_task.dart';
import '../models/user_model.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class DatabaseHelper {
  static const String _modulesBox = 'modules';
  static const String _userBox = 'userBox';
  static const String _notesBox = 'notes';
  static const String _noteDraftsBox = 'noteDrafts';

  static const _secureStorage = FlutterSecureStorage();
  static const _encryptionKeyName = 'hive_encryption_key';

  /// The AES key lives in the platform keystore/keychain, not in the Hive
  /// files themselves - losing it (e.g. clearing secure storage without
  /// clearing app data) makes the boxes unreadable.
  static Future<HiveAesCipher> _loadOrCreateCipher() async {
    final existing = await _secureStorage.read(key: _encryptionKeyName);
    if (existing != null) {
      return HiveAesCipher(base64Url.decode(existing));
    }
    final key = Hive.generateSecureKey();
    await _secureStorage.write(key: _encryptionKeyName, value: base64UrlEncode(key));
    return HiveAesCipher(key);
  }

  /// Opens [name] with [cipher]. A box written before encryption was added
  /// fails the cipher's checksum on open - in that case, read it back in
  /// plaintext once and rewrite it encrypted in place.
  static Future<Box<T>> _openEncryptedBox<T>(String name, HiveAesCipher cipher) async {
    try {
      return await Hive.openBox<T>(name, encryptionCipher: cipher);
    } on HiveError {
      final plain = await Hive.openBox<T>(name);
      final entries = Map<dynamic, T>.from(plain.toMap());
      await plain.close();
      await Hive.deleteBoxFromDisk(name);
      final encrypted = await Hive.openBox<T>(name, encryptionCipher: cipher);
      await encrypted.putAll(entries);
      return encrypted;
    }
  }

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ModuleAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(ProjectTaskAdapter());
    final cipher = await _loadOrCreateCipher();
    await _openEncryptedBox<Module>(_modulesBox, cipher);
    await _openEncryptedBox<UserModel>(_userBox, cipher);
    await _openEncryptedBox<Note>(_notesBox, cipher);
    await _openEncryptedBox<dynamic>(_noteDraftsBox, cipher);

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

  static List<Module> getProjects() =>
      _modules.values.where((m) => m.isProject).toList();

  static Future<void> addModule(Module module) async {
    // Counts module creation as activity too, same as a note's updatedAt
    // being set at construction - without this a freshly created module
    // would be invisible to getRecentActivity until its first edit.
    module.updatedAt ??= DateTime.now();
    await _modules.add(module);
  }

  static Future<void> updateModule(Module module) async {
    module.updatedAt = DateTime.now();
    await module.save();
  }

  /// Looks up a module by id, or null if it doesn't exist (e.g. it was
  /// already deleted by a concurrent action). Deliberately not using
  /// `Iterable.firstWhere` here, since that throws a StateError - and an
  /// uncaught StateError from a double-tapped delete button would crash
  /// the app rather than just being a harmless no-op.
  static Module? _findModule(String moduleId) {
    for (final m in _modules.values) {
      if (m.id == moduleId) return m;
    }
    return null;
  }

  static Future<void> deleteModule(String moduleId) async {
    final module = _findModule(moduleId);
    if (module == null) return; // already deleted - nothing to do

    // Delete the module along with any submodules that point at it,
    // and any notes that belong to it.
    final children = getSubmodules(moduleId);
    for (final child in children) {
      await deleteModule(child.id);
    }
    for (final note in getNotesForModule(moduleId)) {
      await note.delete();
    }
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
    String? aiSource,
  }) async {
    final note = Note(
      id: generateId(),
      moduleId: moduleId,
      title: title,
      content: content,
      tags: tags,
      aiSource: aiSource,
    );
    await _notes.add(note);
    return note;
  }

  static Future<void> updateNote(Note note,
      {String? title, String? content, List<String>? tags, String? aiSource, String? moduleId}) async {
    await note.update(title: title, content: content, tags: tags, aiSource: aiSource, moduleId: moduleId);
  }

  static Future<void> deleteNote(String noteId) async {
    await _noteDrafts.delete(noteId);
    for (final note in _notes.values) {
      if (note.id == noteId) {
        await note.delete();
        return;
      }
    }
    // Already deleted (e.g. a concurrent delete) - nothing to do.
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

  // --- Activity ---

  /// The most recently changed notes and modules, newest first, for the
  /// dashboard's activity feed. A note counts as activity from the moment
  /// it's created (its `updatedAt` is always set); a module counts only
  /// once it's actually been created or edited through [addModule] /
  /// [updateModule] - one saved before [Module.updatedAt] existed, and
  /// never touched since, has nothing to report and is left out rather
  /// than sorted in at the epoch.
  ///
  /// [moduleId] restricts to that module's own activity plus notes inside
  /// it; [tag] restricts to notes carrying that tag (modules have no tags,
  /// so a [tag] filter always excludes module activity); [after]/[before]
  /// bound the timestamp range (inclusive on both ends). Deliberately
  /// plain [DateTime]s rather than a Flutter `DateTimeRange`, so this
  /// stays a pure data-layer query with no UI-toolkit dependency.
  static List<ActivityItem> getRecentActivity({
    int limit = 20,
    String? moduleId,
    String? tag,
    DateTime? after,
    DateTime? before,
  }) {
    bool inRange(DateTime t) =>
        (after == null || !t.isBefore(after)) && (before == null || !t.isAfter(before));

    final items = <ActivityItem>[
      for (final note in _notes.values)
        if ((moduleId == null || note.moduleId == moduleId) &&
            (tag == null || note.tags.contains(tag)) &&
            inRange(note.updatedAt))
          ActivityItem(
            type: ActivityType.note,
            id: note.id,
            title: note.title,
            moduleId: note.moduleId,
            timestamp: note.updatedAt,
          ),
      for (final module in _modules.values)
        if (module.updatedAt != null &&
            tag == null &&
            (moduleId == null || module.id == moduleId) &&
            inRange(module.updatedAt!))
          ActivityItem(
            type: ActivityType.module,
            id: module.id,
            title: module.title,
            moduleId: module.id,
            timestamp: module.updatedAt!,
          ),
    ];
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.take(limit).toList();
  }

  // --- Note drafts ---
  //
  // A separate, untyped box (plain maps, no HiveObject) holding in-progress
  // edits for existing notes, keyed by note id. Written far more often than
  // the note editor's own 2s autosave, so it catches edits made just before
  // an unclean close (app/window killed outright, skipping the editor's
  // normal save-on-exit flow) that autosave hasn't committed yet. Cleared as
  // soon as a save or autosave makes the real Note match it again.
  static Box get _noteDrafts => Hive.box(_noteDraftsBox);

  static Map<String, dynamic>? getDraft(String noteId) =>
      (_noteDrafts.get(noteId) as Map?)?.cast<String, dynamic>();

  static Future<void> saveDraft(String noteId,
      {required String title, required String content, required List<String> tags}) async {
    await _noteDrafts.put(noteId, {'title': title, 'content': content, 'tags': tags});
  }

  static Future<void> clearDraft(String noteId) async => _noteDrafts.delete(noteId);

  // --- Export / Import ---

  /// Strips control characters (anything but tab/newline/carriage return)
  /// from exported note text and tags - leftover paste artifacts or an
  /// attempt to smuggle terminal escape sequences into a file that gets
  /// written and re-displayed verbatim.
  static String _sanitizeForExport(String value) =>
      value.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

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
                'isProject': m.isProject,
                'status': m.status,
                'repoUrl': m.repoUrl,
                'deadline': m.deadline?.toIso8601String(),
                'updatedAt': m.updatedAt?.toIso8601String(),
                'tasks': m.tasks
                    .map((t) => {
                          'title': t.title,
                          'done': t.done,
                          'dueDate': t.dueDate?.toIso8601String(),
                        })
                    .toList(),
              })
          .toList(),
      'notes': _notes.values
          .map((n) => {
                'id': n.id,
                'moduleId': n.moduleId,
                'title': _sanitizeForExport(n.title),
                'content': _sanitizeForExport(n.content),
                'createdAt': n.createdAt.toIso8601String(),
                'updatedAt': n.updatedAt.toIso8601String(),
                'tags': n.tags.map(_sanitizeForExport).toList(),
                'aiSource': n.aiSource,
              })
          .toList(),
    };
  }

  static String exportDataAsJson() =>
      const JsonEncoder.withIndent('  ').convert(exportData());

  /// Replaces every module and note with the contents of a previously
  /// exported JSON string. Throws a [FormatException] if [jsonStr] doesn't
  /// look like a DevLog export.
  static Future<void> importDataFromJson(String jsonStr) async {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic> ||
        decoded['modules'] is! List ||
        decoded['notes'] is! List) {
      throw const FormatException('Not a valid DevLog export file.');
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
        isProject: map['isProject'] as bool? ?? false,
        status: map['status'] as String? ?? 'in_progress',
        repoUrl: map['repoUrl'] as String?,
        deadline: map['deadline'] != null
            ? DateTime.parse(map['deadline'] as String)
            : null,
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
        tasks: (map['tasks'] as List?)
            ?.map((t) => ProjectTask(
                  title: (t as Map)['title'] as String,
                  done: t['done'] as bool? ?? false,
                  dueDate: t['dueDate'] != null ? DateTime.parse(t['dueDate'] as String) : null,
                ))
            .toList(),
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
        aiSource: map['aiSource'] as String?,
      ));
    }
  }

  /// A full snapshot for backup/restore: everything [exportData] covers,
  /// plus the user's profile and theme preference, which "Export data"
  /// deliberately leaves out since that format is meant for sharing/moving
  /// module content rather than restoring a whole device's state.
  static Map<String, dynamic> exportBackupData() {
    final data = exportData();
    final user = _users.isNotEmpty ? _users.getAt(0) : null;
    return {
      ...data,
      'user': user == null
          ? null
          : {
              'name': user.name,
              'email': user.email,
              'avatarPath': user.avatarPath,
              'isDarkMode': user.isDarkMode,
            },
    };
  }

  static String exportBackupAsJson() =>
      const JsonEncoder.withIndent('  ').convert(exportBackupData());

  /// Restores a full device snapshot produced by [exportBackupAsJson]:
  /// every module and note (via [importDataFromJson]), plus the user's
  /// profile and theme preference. Throws a [FormatException] if [jsonStr]
  /// doesn't look like a DevLog backup.
  static Future<void> restoreBackupFromJson(String jsonStr) async {
    await importDataFromJson(jsonStr);

    final userJson = (jsonDecode(jsonStr) as Map<String, dynamic>)['user'] as Map<String, dynamic>?;
    if (userJson == null) return;

    final isDark = userJson['isDarkMode'] as bool? ?? true;
    if (_users.isEmpty) {
      await _users.add(UserModel(
        name: userJson['name'] as String? ?? 'User',
        email: userJson['email'] as String? ?? '',
        avatarPath: userJson['avatarPath'] as String? ?? 'assets/images/default_avatar.png',
        isDarkMode: isDark,
      ));
    } else {
      final user = _users.getAt(0)!;
      user.name = userJson['name'] as String? ?? user.name;
      user.email = userJson['email'] as String? ?? user.email;
      user.avatarPath = userJson['avatarPath'] as String? ?? user.avatarPath;
      user.isDarkMode = isDark;
      await user.save();
    }
    AppColors.setDark(isDark);
  }

  // --- Danger zone ---

  /// Deletes every module and note. Leaves the user's profile and theme
  /// preference untouched.
  static Future<void> clearAllData() async {
    await _modules.clear();
    await _notes.clear();
    await _noteDrafts.clear();
  }
}
