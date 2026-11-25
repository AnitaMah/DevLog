// Unit tests for DatabaseHelper's module + note CRUD logic.
//
// Uses an isolated, temporary Hive database per test (via Hive.init with a
// fresh temp dir) rather than DatabaseHelper.init() itself, since the latter
// calls Hive.initFlutter() which needs the path_provider plugin — not
// available in plain `flutter test`.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/activity_item.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/models/project_task.dart';
import 'package:dev_log/models/user_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dev_log_db_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ModuleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(NoteAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ProjectTaskAdapter());

    await Hive.openBox<Module>('modules');
    await Hive.openBox<UserModel>('userBox');
    await Hive.openBox<Note>('notes');
    await Hive.openBox('noteDrafts');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Module CRUD', () {
    test('addModule stores a root module', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'C Basics'));

      final all = DatabaseHelper.getAllModules();
      expect(all, hasLength(1));
      expect(all.first.title, 'C Basics');
      expect(all.first.parentId, isNull);
    });

    test('getRootModules excludes modules with a parentId', () async {
      await DatabaseHelper.addModule(Module(id: 'root', title: 'Unix'));
      await DatabaseHelper.addModule(Module(id: 'child', title: 'Shell Basics', parentId: 'root'));

      final roots = DatabaseHelper.getRootModules();
      expect(roots.map((m) => m.id), ['root']);
    });

    test('getSubmodules returns only children of the given parent', () async {
      await DatabaseHelper.addModule(Module(id: 'root', title: 'Git'));
      await DatabaseHelper.addModule(Module(id: 'child1', title: 'Branching', parentId: 'root'));
      await DatabaseHelper.addModule(Module(id: 'child2', title: 'Rebasing', parentId: 'root'));
      await DatabaseHelper.addModule(Module(id: 'unrelated', title: 'Docker'));

      final children = DatabaseHelper.getSubmodules('root');
      expect(children.map((m) => m.id).toSet(), {'child1', 'child2'});
    });

    test('updateModule persists field changes', () async {
      final module = Module(id: 'm1', title: 'Old Title');
      await DatabaseHelper.addModule(module);

      module.title = 'New Title';
      module.description = 'Updated description';
      await DatabaseHelper.updateModule(module);

      final reloaded = DatabaseHelper.getAllModules().first;
      expect(reloaded.title, 'New Title');
      expect(reloaded.description, 'Updated description');
    });

    test('deleteModule cascades to submodules and notes', () async {
      await DatabaseHelper.addModule(Module(id: 'root', title: 'Algorithms'));
      await DatabaseHelper.addModule(Module(id: 'child', title: 'Sorting', parentId: 'root'));
      await DatabaseHelper.addNote('root', title: 'Root note');
      await DatabaseHelper.addNote('child', title: 'Child note');

      await DatabaseHelper.deleteModule('root');

      expect(DatabaseHelper.getAllModules(), isEmpty);
      expect(DatabaseHelper.getAllNotes(), isEmpty);
    });

    test('deleteModule on an already-deleted id is a no-op, not a crash', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Networking'));

      await DatabaseHelper.deleteModule('m1');
      // Second delete of the same id (e.g. a double-tapped delete button,
      // or deleting a submodule that a parent's cascade already removed)
      // should not throw.
      await DatabaseHelper.deleteModule('m1');

      expect(DatabaseHelper.getAllModules(), isEmpty);
    });
  });

  group('Projects', () {
    test('a module is not a project by default', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'C Basics'));

      expect(DatabaseHelper.getProjects(), isEmpty);
    });

    test('getProjects returns only modules marked isProject', () async {
      final project = Module(id: 'p1', title: 'My App', isProject: true);
      await DatabaseHelper.addModule(project);
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'C Basics'));

      final projects = DatabaseHelper.getProjects();
      expect(projects.map((m) => m.id), ['p1']);
    });

    test('project fields (status, repoUrl, deadline, tasks) persist via updateModule', () async {
      final module = Module(id: 'p1', title: 'My App', isProject: true);
      await DatabaseHelper.addModule(module);

      final deadline = DateTime(2026, 12, 1);
      module.status = 'done';
      module.repoUrl = 'https://example.com/repo';
      module.deadline = deadline;
      module.tasks.add(ProjectTask(title: 'Write README'));
      await DatabaseHelper.updateModule(module);

      final reloaded = DatabaseHelper.getProjects().first;
      expect(reloaded.status, 'done');
      expect(reloaded.repoUrl, 'https://example.com/repo');
      expect(reloaded.deadline, deadline);
      expect(reloaded.tasks, hasLength(1));
      expect(reloaded.tasks.first.title, 'Write README');
      expect(reloaded.tasks.first.done, isFalse);
    });

    test('a module saved before project fields existed reads back with safe defaults', () async {
      // Simulates a real pre-existing record: written with the old Module
      // shape (no HiveFields 7-11 at all), not just unset in a newer shape.
      await DatabaseHelper.importDataFromJson('''
      {
        "version": 1, "exportedAt": "2024-01-01T00:00:00.000",
        "modules": [{"id": "old1", "title": "Old Module", "parentId": null, "lastOpenedAt": null, "iconName": "folder", "description": ""}],
        "notes": []
      }
      ''');

      final module = DatabaseHelper.getAllModules().first;
      expect(module.isProject, isFalse);
      expect(module.status, 'in_progress');
      expect(module.repoUrl, isNull);
      expect(module.deadline, isNull);
      expect(module.tasks, isEmpty);
    });
  });

  group('Note CRUD', () {
    test('addNote links a note to its module', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Python'));
      final note = await DatabaseHelper.addNote('m1', title: 'Loops', content: 'for/while');

      expect(note.moduleId, 'm1');
      expect(note.title, 'Loops');
      expect(note.content, 'for/while');
    });

    test('getNotesForModule only returns notes for that module', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Python'));
      await DatabaseHelper.addModule(Module(id: 'm2', title: 'Dart'));
      await DatabaseHelper.addNote('m1', title: 'Note A');
      await DatabaseHelper.addNote('m2', title: 'Note B');

      final notesForM1 = DatabaseHelper.getNotesForModule('m1');
      expect(notesForM1, hasLength(1));
      expect(notesForM1.first.title, 'Note A');
    });

    test('getNotesCountForModule matches actual note count', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Web'));
      await DatabaseHelper.addNote('m1');
      await DatabaseHelper.addNote('m1');
      await DatabaseHelper.addNote('m1');

      expect(DatabaseHelper.getNotesCountForModule('m1'), 3);
    });

    test('updateNote changes title/content and bumps updatedAt', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Docker'));
      final note = await DatabaseHelper.addNote('m1', title: 'Draft', content: 'wip');
      final originalUpdatedAt = note.updatedAt;

      await Future.delayed(const Duration(milliseconds: 5));
      await DatabaseHelper.updateNote(note, title: 'Final', content: 'done');

      expect(note.title, 'Final');
      expect(note.content, 'done');
      expect(note.updatedAt.isAfter(originalUpdatedAt), isTrue);
    });

    test('deleteNote removes it from storage', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Systeme'));
      final note = await DatabaseHelper.addNote('m1', title: 'Temp');

      await DatabaseHelper.deleteNote(note.id);

      expect(DatabaseHelper.getNotesForModule('m1'), isEmpty);
    });

    test('deleteNote on an already-deleted id is a no-op, not a crash', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Systeme'));
      final note = await DatabaseHelper.addNote('m1', title: 'Temp');

      await DatabaseHelper.deleteNote(note.id);
      // Second delete of the same id (e.g. a double-tapped delete button)
      // should not throw.
      await DatabaseHelper.deleteNote(note.id);

      expect(DatabaseHelper.getNotesForModule('m1'), isEmpty);
    });

    test('deleteNote also clears any pending draft for that note', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Systeme'));
      final note = await DatabaseHelper.addNote('m1', title: 'Temp');
      await DatabaseHelper.saveDraft(note.id, title: 'Temp draft', content: 'wip', tags: const []);

      await DatabaseHelper.deleteNote(note.id);

      expect(DatabaseHelper.getDraft(note.id), isNull);
    });
  });

  group('Note drafts', () {
    test('saveDraft then getDraft round-trips title/content/tags', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Rust'));
      final note = await DatabaseHelper.addNote('m1', title: 'Ownership');

      await DatabaseHelper.saveDraft(note.id,
          title: 'Ownership (edited)', content: 'borrow checker notes', tags: ['rust', 'wip']);

      final draft = DatabaseHelper.getDraft(note.id);
      expect(draft, isNotNull);
      expect(draft!['title'], 'Ownership (edited)');
      expect(draft['content'], 'borrow checker notes');
      expect(draft['tags'], ['rust', 'wip']);
    });

    test('getDraft returns null when no draft was ever saved', () async {
      expect(DatabaseHelper.getDraft('no-such-note'), isNull);
    });

    test('clearDraft removes a saved draft', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Rust'));
      final note = await DatabaseHelper.addNote('m1', title: 'Ownership');
      await DatabaseHelper.saveDraft(note.id, title: 'x', content: 'y', tags: const []);

      await DatabaseHelper.clearDraft(note.id);

      expect(DatabaseHelper.getDraft(note.id), isNull);
    });

    test('saveDraft overwrites a previous draft for the same note', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Rust'));
      final note = await DatabaseHelper.addNote('m1', title: 'Ownership');

      await DatabaseHelper.saveDraft(note.id, title: 'First', content: 'a', tags: const []);
      await DatabaseHelper.saveDraft(note.id, title: 'Second', content: 'b', tags: const []);

      final draft = DatabaseHelper.getDraft(note.id);
      expect(draft!['title'], 'Second');
      expect(draft['content'], 'b');
    });

    test('clearAllData also clears note drafts', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Rust'));
      final note = await DatabaseHelper.addNote('m1', title: 'Ownership');
      await DatabaseHelper.saveDraft(note.id, title: 'x', content: 'y', tags: const []);

      await DatabaseHelper.clearAllData();

      expect(DatabaseHelper.getDraft(note.id), isNull);
    });
  });

  group('Tags', () {
    test('addNote stores tags on the note', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Git'));
      final note = await DatabaseHelper.addNote('m1', title: 'Rebase', tags: ['git', 'advanced']);

      expect(note.tags, containsAll(['git', 'advanced']));
    });

    test('updateNote can replace a note\'s tags', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Git'));
      final note = await DatabaseHelper.addNote('m1', tags: ['old']);

      await DatabaseHelper.updateNote(note, tags: ['new', 'shiny']);

      expect(note.tags, ['new', 'shiny']);
    });

    test('getAllTagsWithCounts aggregates and sorts by popularity', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Git'));
      await DatabaseHelper.addNote('m1', tags: ['git', 'basics']);
      await DatabaseHelper.addNote('m1', tags: ['git']);
      await DatabaseHelper.addNote('m1', tags: ['git', 'basics']);

      final counts = DatabaseHelper.getAllTagsWithCounts();

      expect(counts.first.key, 'git');
      expect(counts.first.value, 3);
      expect(counts.firstWhere((e) => e.key == 'basics').value, 2);
    });

    test('getNotesByTag returns only notes with that tag', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Git'));
      await DatabaseHelper.addNote('m1', title: 'A', tags: ['git']);
      await DatabaseHelper.addNote('m1', title: 'B', tags: ['docker']);

      final tagged = DatabaseHelper.getNotesByTag('git');

      expect(tagged, hasLength(1));
      expect(tagged.first.title, 'A');
    });
  });

  group('Activity', () {
    test('getRecentActivity sorts notes and modules together by recency', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Rust'));
      await Future.delayed(const Duration(milliseconds: 5));
      final note = await DatabaseHelper.addNote('m1', title: 'Ownership');
      await Future.delayed(const Duration(milliseconds: 5));
      final module = DatabaseHelper.getAllModules().first;
      module.description = 'Updated';
      await DatabaseHelper.updateModule(module);

      final activity = DatabaseHelper.getRecentActivity();

      // One entry per record (its latest change), not one per edit: the
      // module was both created and later updated, but only its newest
      // timestamp - from the update - appears.
      expect(activity.map((a) => a.id), [module.id, note.id]);
      expect(activity[0].type, ActivityType.module);
      expect(activity[1].type, ActivityType.note);
      expect(activity[1].title, 'Ownership');
      expect(activity[1].moduleId, 'm1');
    });

    test('getRecentActivity respects limit', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Go'));
      for (var i = 0; i < 5; i++) {
        await DatabaseHelper.addNote('m1', title: 'Note $i');
      }

      expect(DatabaseHelper.getRecentActivity(limit: 3), hasLength(3));
    });

    test('a module never created/edited through DatabaseHelper has no activity', () async {
      // Simulates a record written before Module.updatedAt existed.
      await DatabaseHelper.importDataFromJson('''
      {
        "version": 1, "exportedAt": "2024-01-01T00:00:00.000",
        "modules": [{"id": "old1", "title": "Old Module", "parentId": null}],
        "notes": []
      }
      ''');

      expect(DatabaseHelper.getRecentActivity(), isEmpty);
    });

    test('addModule counts creation as activity', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Zig'));

      final activity = DatabaseHelper.getRecentActivity();
      expect(activity, hasLength(1));
      expect(activity.first.type, ActivityType.module);
      expect(activity.first.id, 'm1');
    });

    test('getRecentActivity moduleId filter includes that module and its notes only', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Haskell'));
      await DatabaseHelper.addModule(Module(id: 'm2', title: 'Elixir'));
      await DatabaseHelper.addNote('m1', title: 'Monads');
      await DatabaseHelper.addNote('m2', title: 'Processes');

      final activity = DatabaseHelper.getRecentActivity(moduleId: 'm1');

      expect(activity.every((a) => a.moduleId == 'm1'), isTrue);
      expect(activity.any((a) => a.title == 'Monads'), isTrue);
      expect(activity.any((a) => a.title == 'Processes'), isFalse);
    });

    test('getRecentActivity tag filter matches tagged notes and excludes modules', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Clojure'));
      await DatabaseHelper.addNote('m1', title: 'Tagged', tags: ['lisp']);
      await DatabaseHelper.addNote('m1', title: 'Untagged');

      final activity = DatabaseHelper.getRecentActivity(tag: 'lisp');

      expect(activity.map((a) => a.title), ['Tagged']);
    });

    test('getRecentActivity after/before bound the timestamp range', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Erlang'));
      final early = await DatabaseHelper.addNote('m1', title: 'Early');
      await Future.delayed(const Duration(milliseconds: 5));
      final cutoff = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 5));
      await DatabaseHelper.addNote('m1', title: 'Late');

      final activity = DatabaseHelper.getRecentActivity(after: cutoff);

      expect(activity.any((a) => a.title == 'Early'), isFalse);
      expect(activity.any((a) => a.title == 'Late'), isTrue);
      expect(early.updatedAt.isBefore(cutoff), isTrue);
    });
  });

  group('AI source', () {
    test('addNote stores aiSource on the note', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Chats'));
      final note = await DatabaseHelper.addNote('m1', title: 'Convo', aiSource: 'claude');

      expect(note.aiSource, 'claude');
    });

    test('updateNote can set aiSource', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Chats'));
      final note = await DatabaseHelper.addNote('m1', title: 'Convo');

      await DatabaseHelper.updateNote(note, aiSource: 'gemini');

      expect(note.aiSource, 'gemini');
    });

    test('a note created with no aiSource stays null', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Chats'));
      final note = await DatabaseHelper.addNote('m1', title: 'Regular note');

      expect(note.aiSource, isNull);
    });
  });

  group('Export / Import', () {
    test('exportData captures every module and note field', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Git', description: 'vcs'));
      await DatabaseHelper.addNote('m1', title: 'Rebase', content: 'body', tags: ['git']);

      final data = DatabaseHelper.exportData();

      expect(data['modules'], hasLength(1));
      expect(data['notes'], hasLength(1));
      expect((data['modules'] as List).first['title'], 'Git');
      expect((data['notes'] as List).first['tags'], ['git']);
    });

    test('exportData captures aiSource', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Chats'));
      await DatabaseHelper.addNote('m1', title: 'Convo', aiSource: 'claude');

      final data = DatabaseHelper.exportData();

      expect((data['notes'] as List).first['aiSource'], 'claude');
    });

    test('exportData captures project fields', () async {
      final deadline = DateTime(2026, 12, 1);
      await DatabaseHelper.addModule(Module(
        id: 'p1',
        title: 'My App',
        isProject: true,
        status: 'done',
        repoUrl: 'https://example.com/repo',
        deadline: deadline,
        tasks: [ProjectTask(title: 'Ship it', done: true)],
      ));

      final data = DatabaseHelper.exportData();
      final module = (data['modules'] as List).first as Map;
      expect(module['isProject'], isTrue);
      expect(module['status'], 'done');
      expect(module['repoUrl'], 'https://example.com/repo');
      expect(module['deadline'], deadline.toIso8601String());
      expect(module['tasks'], [{'title': 'Ship it', 'done': true, 'dueDate': null}]);
    });

    test('exportData captures a task\'s due date', () async {
      final dueDate = DateTime(2026, 12, 12);
      await DatabaseHelper.addModule(Module(
        id: 'p1',
        title: 'My App',
        isProject: true,
        tasks: [ProjectTask(title: 'Ship it', dueDate: dueDate)],
      ));

      final data = DatabaseHelper.exportData();
      final module = (data['modules'] as List).first as Map;
      expect(module['tasks'], [{'title': 'Ship it', 'done': false, 'dueDate': dueDate.toIso8601String()}]);
    });

    test('importDataFromJson round-trips through exportDataAsJson', () async {
      final deadline = DateTime(2026, 12, 1);
      await DatabaseHelper.addModule(Module(id: 'root', title: 'C', description: 'lang'));
      await DatabaseHelper.addModule(Module(id: 'child', title: 'Pointers', parentId: 'root'));
      await DatabaseHelper.addModule(Module(
        id: 'proj',
        title: 'My App',
        isProject: true,
        status: 'planning',
        repoUrl: 'https://example.com/repo',
        deadline: deadline,
        tasks: [ProjectTask(title: 'Write README', dueDate: DateTime(2026, 12, 12))],
      ));
      await DatabaseHelper.addNote('root', title: 'Intro', content: 'hi', tags: ['c', 'basics'], aiSource: 'gemini');

      final json = DatabaseHelper.exportDataAsJson();

      await DatabaseHelper.clearAllData();
      expect(DatabaseHelper.getAllModules(), isEmpty);

      await DatabaseHelper.importDataFromJson(json);

      final modules = DatabaseHelper.getAllModules();
      final notes = DatabaseHelper.getAllNotes();
      expect(modules, hasLength(3));
      expect(notes, hasLength(1));
      expect(modules.firstWhere((m) => m.id == 'child').parentId, 'root');
      expect(notes.first.tags, ['c', 'basics']);
      expect(notes.first.aiSource, 'gemini');

      final project = modules.firstWhere((m) => m.id == 'proj');
      expect(project.isProject, isTrue);
      expect(project.status, 'planning');
      expect(project.repoUrl, 'https://example.com/repo');
      expect(project.deadline, deadline);
      expect(project.tasks, hasLength(1));
      expect(project.tasks.first.title, 'Write README');
      expect(project.tasks.first.dueDate, DateTime(2026, 12, 12));
    });

    test('importDataFromJson replaces existing data rather than merging', () async {
      await DatabaseHelper.addModule(Module(id: 'old', title: 'Old module'));
      final json = DatabaseHelper.exportDataAsJson(); // captures only 'old'

      await DatabaseHelper.addModule(Module(id: 'new', title: 'New module'));
      await DatabaseHelper.importDataFromJson(json);

      final modules = DatabaseHelper.getAllModules();
      expect(modules.map((m) => m.id), ['old']);
    });

    test('importDataFromJson rejects malformed input', () async {
      expect(
        () => DatabaseHelper.importDataFromJson('{"foo": "bar"}'),
        throwsFormatException,
      );
    });

    test('importDataFromJson tolerates export files from before aiSource existed', () async {
      // Simulates a real export produced by an older build of the app: no
      // "aiSource" key in the note map at all.
      const legacyJson = '''
      {
        "version": 1, "exportedAt": "2024-01-01T00:00:00.000",
        "modules": [{"id": "m1", "title": "Old", "parentId": null, "lastOpenedAt": null, "iconName": "folder", "description": ""}],
        "notes": [{"id": "n1", "moduleId": "m1", "title": "Old note", "content": "hi", "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000", "tags": []}]
      }
      ''';

      await DatabaseHelper.importDataFromJson(legacyJson);

      expect(DatabaseHelper.getAllNotes().first.aiSource, isNull);
    });
  });

  group('Backup', () {
    test('exportBackupData includes everything exportData does, plus the user profile', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Notes'));
      await DatabaseHelper.saveThemePreference(true);
      final user = Hive.box<UserModel>('userBox').getAt(0)!;
      user.name = 'Ada';
      user.email = 'ada@example.com';
      await user.save();

      final data = DatabaseHelper.exportBackupData();
      expect(data['modules'], hasLength(1));
      expect(data['user'], {
        'name': 'Ada',
        'email': 'ada@example.com',
        'avatarPath': user.avatarPath,
        'isDarkMode': true,
      });
    });

    test('exportBackupData reports a null user when no profile exists yet', () async {
      final data = DatabaseHelper.exportBackupData();
      expect(data['user'], isNull);
    });

    test('exportBackupAsJson produces valid, re-decodable JSON', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Notes'));
      final decoded = jsonDecode(DatabaseHelper.exportBackupAsJson());
      expect(decoded['modules'], hasLength(1));
    });

    test('restoreBackupFromJson round-trips modules, notes, and the user profile', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Old module'));
      await DatabaseHelper.addNote('m1', title: 'Old note');
      await DatabaseHelper.saveThemePreference(false);
      final user = Hive.box<UserModel>('userBox').getAt(0)!;
      user.name = 'Ada';
      user.email = 'ada@example.com';
      await user.save();

      final json = DatabaseHelper.exportBackupAsJson();

      await DatabaseHelper.clearAllData();
      await Hive.box<UserModel>('userBox').clear();
      await DatabaseHelper.addModule(Module(id: 'new', title: 'New module'));

      await DatabaseHelper.restoreBackupFromJson(json);

      expect(DatabaseHelper.getAllModules().map((m) => m.id), ['m1']);
      expect(DatabaseHelper.getAllNotes().first.title, 'Old note');
      final restoredUser = Hive.box<UserModel>('userBox').getAt(0)!;
      expect(restoredUser.name, 'Ada');
      expect(restoredUser.email, 'ada@example.com');
      expect(restoredUser.isDarkMode, isFalse);
    });

    test('restoreBackupFromJson leaves the profile untouched when the backup has none', () async {
      await DatabaseHelper.saveThemePreference(true);
      final json = DatabaseHelper.exportDataAsJson(); // no 'user' key at all

      await DatabaseHelper.restoreBackupFromJson(json);

      expect(Hive.box<UserModel>('userBox').getAt(0)!.isDarkMode, isTrue);
    });

    test('restoreBackupFromJson rejects malformed input', () async {
      expect(
        () => DatabaseHelper.restoreBackupFromJson('{"foo": "bar"}'),
        throwsFormatException,
      );
    });
  });

  group('clearAllData', () {
    test('removes every module and note', () async {
      await DatabaseHelper.addModule(Module(id: 'm1', title: 'Git'));
      await DatabaseHelper.addModule(Module(id: 'm2', title: 'Docker'));
      await DatabaseHelper.addNote('m1', title: 'A');
      await DatabaseHelper.addNote('m2', title: 'B');

      await DatabaseHelper.clearAllData();

      expect(DatabaseHelper.getAllModules(), isEmpty);
      expect(DatabaseHelper.getAllNotes(), isEmpty);
    });
  });
}
