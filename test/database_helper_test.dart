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
  });
}
