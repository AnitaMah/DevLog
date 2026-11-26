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
    await Hive.openBox('noteDrafts');

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

  // Skipped: any Hive box write hangs when called from inside testWidgets on
  // this Flutter/Hive combo - see https://github.com/AnitaMah/DevLog/issues/2
  testWidgets(
      'typing a title and tapping save creates exactly one note',
      skip: true,
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

  // Skipped: any Hive box write hangs when called from inside testWidgets on
  // this Flutter/Hive combo - see https://github.com/AnitaMah/DevLog/issues/2
  testWidgets(
      'typing a tag but not pressing Enter still saves it',
      skip: true,
      (tester) async {
    // Regression test: the tag input box only turned text into a real tag
    // on Enter (onSubmitted). Typing a tag and then clicking the save
    // button directly - without hitting Enter first - used to silently
    // drop that tag with no warning at all.
    await tester.pumpWidget(const MaterialApp(
      home: NoteEditorScreen(moduleId: 'm1'),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Note title'), 'Tagged Note');
    await tester.enterText(find.widgetWithText(TextField, '+ add tag'), 'flutter');
    // Deliberately not pressing Enter - go straight to save.
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final notes = DatabaseHelper.getAllNotes();
    expect(notes, hasLength(1));
    expect(notes.first.tags, contains('flutter'));
  });

  group('draft recovery', () {
    // The note (and its draft) are created here in setUp - plain async, not
    // inside testWidgets - to dodge the Hive-write hang tracked in issue #2.
    late Note noteWithDifferingDraft;
    late Note noteWithNoDraft;
    late Note noteWithMatchingDraft;

    setUp(() async {
      noteWithDifferingDraft =
          await DatabaseHelper.addNote('m1', title: 'Saved title', content: 'saved body');
      await DatabaseHelper.saveDraft(noteWithDifferingDraft.id,
          title: 'Draft title', content: 'draft body', tags: const []);

      noteWithNoDraft = await DatabaseHelper.addNote('m1', title: 'No draft', content: 'body');

      noteWithMatchingDraft = await DatabaseHelper.addNote('m1', title: 'Same', content: 'same body');
      await DatabaseHelper.saveDraft(noteWithMatchingDraft.id,
          title: 'Same', content: 'same body', tags: const []);
    });

    testWidgets('prompts to recover a draft that differs from the saved note',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: NoteEditorScreen(note: noteWithDifferingDraft)));
      await tester.pumpAndSettle();

      expect(find.text('Recover unsaved draft?'), findsOneWidget);

      await tester.tap(find.text('Recover'));
      await tester.pumpAndSettle();

      expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'Draft title'))
              .controller!
              .text,
          'Draft title');
      expect(find.text('draft body'), findsOneWidget);

      // Dispose the screen now, cancelling the autosave timer the recovery
      // flow armed - otherwise it's still pending (real, 2s) when the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('does not prompt when there is no draft', (tester) async {
      await tester.pumpWidget(MaterialApp(home: NoteEditorScreen(note: noteWithNoDraft)));
      await tester.pumpAndSettle();

      expect(find.text('Recover unsaved draft?'), findsNothing);
    });

    // Skipped: this path clears the stale draft via a Hive write fired from
    // a postFrameCallback during the widget's lifecycle, which hangs on this
    // Flutter/Hive combo inside testWidgets - see
    // https://github.com/AnitaMah/DevLog/issues/2
    testWidgets('does not prompt when the draft matches the saved note',
        skip: true, (tester) async {
      await tester.pumpWidget(MaterialApp(home: NoteEditorScreen(note: noteWithMatchingDraft)));
      await tester.pumpAndSettle();

      expect(find.text('Recover unsaved draft?'), findsNothing);
    });
  });

  group('undo/redo', () {
    // These never tap save, so they never touch Hive and aren't affected by
    // the hang tracked in issue #2.

    testWidgets('rapid typing groups into one undo step', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: NoteEditorScreen(moduleId: 'm1'),
      ));
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(TextField, 'Note title');
      await tester.enterText(titleField, 'H');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(titleField, 'He');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(titleField, 'Hel');
      // Past the 800ms checkpoint-grouping window - commits one step.
      await tester.pump(const Duration(milliseconds: 900));

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();

      expect(tester.widget<TextField>(titleField).controller!.text, isEmpty);

      await tester.tap(find.byIcon(Icons.redo));
      await tester.pump();

      expect(tester.widget<TextField>(titleField).controller!.text, 'Hel');

      // Dispose the screen now, cancelling its pending autosave timer -
      // otherwise it's still armed (real, 2s) when the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('undo reverts a tag add, redo reapplies it', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: NoteEditorScreen(moduleId: 'm1'),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '+ add tag'), 'flutter');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('flutter'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(find.text('flutter'), findsNothing);

      await tester.tap(find.byIcon(Icons.redo));
      await tester.pump();
      expect(find.text('flutter'), findsOneWidget);

      // Dispose the screen now, cancelling its pending autosave timer -
      // otherwise it's still armed (real, 2s) when the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('undo/redo buttons are disabled until there is history', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: NoteEditorScreen(moduleId: 'm1'),
      ));
      await tester.pumpAndSettle();

      IconButton iconButton(IconData icon) =>
          tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon));

      expect(iconButton(Icons.undo).onPressed, isNull);
      expect(iconButton(Icons.redo).onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Note title'), 'Hello');
      await tester.pump(const Duration(milliseconds: 900));

      expect(iconButton(Icons.undo).onPressed, isNotNull);
      expect(iconButton(Icons.redo).onPressed, isNull);

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();

      expect(iconButton(Icons.undo).onPressed, isNull);
      expect(iconButton(Icons.redo).onPressed, isNotNull);

      // Dispose the screen now, cancelling its pending autosave timer -
      // otherwise it's still armed (real, 2s) when the test ends.
      await tester.pumpWidget(const SizedBox());
    });
  });
}
