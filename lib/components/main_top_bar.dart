import 'package:flutter/material.dart';
import 'package:dev_log/components/module_picker_dialog.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/screens/note_editor_screen.dart';

/// Prompts for a module (if needed), creates a new note in it, and opens
/// the note editor. Shared by the "New note" button and the Ctrl+N /
/// Cmd+N keyboard shortcut.
Future<void> createNoteFlow(BuildContext context) async {
  final modules = DatabaseHelper.getAllModules();

  if (modules.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Create a module first, then add notes to it.")),
    );
    return;
  }

  final selected = await showDialog<Module>(
    context: context,
    builder: (_) => ModulePickerDialog(modules: modules),
  );
  if (selected == null) return;

  await selected.updateLastOpenedAt();

  if (context.mounted) {
    // Pass moduleId (not a pre-created note) so the note editor only
    // actually creates a Note record if the user saves it - otherwise
    // backing out of an empty "New Note" used to leave a permanent
    // "Untitled note" behind in the module.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(moduleId: selected.id)),
    );
  }
}
