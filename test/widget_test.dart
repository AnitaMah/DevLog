// Basic smoke test for the DevLog / 42 Guides dashboard.
//
// Sets up an isolated, temporary Hive database (so the test doesn't touch
// real user data and doesn't need the path_provider plugin) and verifies
// the app boots straight into the dashboard.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dev_log/main.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/models/user_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dev_log_test');
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

  testWidgets('DevLogApp boots into the dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const DevLogApp());
    await tester.pumpAndSettle();

    expect(find.text('Guides'), findsOneWidget);
    expect(find.textContaining('Welcome back'), findsOneWidget);
  });
}
