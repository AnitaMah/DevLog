// Regression tests for the "ghost Untitled note" bug: opening the note
// editor to create a note used to persist an empty Note record immediately,
// before the user typed anything or hit save. These verify a Note is only
// ever written to the database once the user actually saves.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:dev_log/screens/note_editor_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('note_editor_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ModuleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(NoteAdapter());

    await Hive.openBox<Module>('modules');
    await Hive.openBox<UserModel>('userBox');
    await Hive.openBox<Note>('notes');

    await DatabaseHelper.addModule(Module(id: 'm1', title: 'Test Module'));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('opening the editor to create a note does not persist anything yet',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: NoteEditorScreen(moduleId: 'm1'),
    ));
    await tester.pumpAndSettle();

    expect(DatabaseHelper.getAllNotes(), isEmpty);
  });

  testWidgets('typing a title and tapping save creates exactly one note',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: NoteEditorScreen(moduleId: 'm1'),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Note title'), 'My New Note');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final notes = DatabaseHelper.getAllNotes();
    expect(notes, hasLength(1));
    expect(notes.first.title, 'My New Note');
    expect(notes.first.moduleId, 'm1');
  });
}
