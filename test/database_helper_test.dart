// Unit tests for DatabaseHelper's module + note CRUD logic.
//
// Uses an isolated, temporary Hive database per test (via Hive.init with a
// fresh temp dir) rather than DatabaseHelper.init() itself, since the latter
// calls Hive.initFlutter() which needs the path_provider plugin — not
// available in plain `flutter test`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/models/user_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dev_log_db_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ModuleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(NoteAdapter());

    await Hive.openBox<Module>('modules');
    await Hive.openBox<UserModel>('userBox');
    await Hive.openBox<Note>('notes');
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

    test('importDataFromJson round-trips through exportDataAsJson', () async {
      await DatabaseHelper.addModule(Module(id: 'root', title: 'C', description: 'lang'));
      await DatabaseHelper.addModule(Module(id: 'child', title: 'Pointers', parentId: 'root'));
      await DatabaseHelper.addNote('root', title: 'Intro', content: 'hi', tags: ['c', 'basics']);

      final json = DatabaseHelper.exportDataAsJson();

      await DatabaseHelper.clearAllData();
      expect(DatabaseHelper.getAllModules(), isEmpty);

      await DatabaseHelper.importDataFromJson(json);

      final modules = DatabaseHelper.getAllModules();
      final notes = DatabaseHelper.getAllNotes();
      expect(modules, hasLength(2));
      expect(notes, hasLength(1));
      expect(modules.firstWhere((m) => m.id == 'child').parentId, 'root');
      expect(notes.first.tags, ['c', 'basics']);
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
