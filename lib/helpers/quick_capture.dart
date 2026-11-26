import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/helpers/id_generator.dart';

/// Saves a quick-capture thought as a note in an "Inbox" module (found by
/// title, created if missing) - no dedicated editor screen, no new module
/// to pick. Title is the captured text's first line (trimmed, capped so a
/// long paste doesn't produce an unreadable title); if the text has no
/// usable first line, falls back to a timestamp-based title so the note
/// is never left untitled.
Future<void> captureQuickNote(String text) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;

  Module? inbox;
  for (final m in DatabaseHelper.getAllModules()) {
    if (m.title == 'Inbox') {
      inbox = m;
      break;
    }
  }
  inbox ??= await _createInboxModule();

  final firstLine = trimmed.split('\n').first.trim();
  final title = firstLine.isNotEmpty
      ? (firstLine.length > 80 ? '${firstLine.substring(0, 80)}…' : firstLine)
      : 'Quick note ${DateTime.now().toIso8601String()}';

  await DatabaseHelper.addNote(inbox.id, title: title, content: trimmed);
}

Future<Module> _createInboxModule() async {
  final module = Module(id: generateId(), title: 'Inbox', iconName: 'inbox');
  await DatabaseHelper.addModule(module);
  return module;
}
