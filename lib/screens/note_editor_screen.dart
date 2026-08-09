import 'package:flutter/material.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Create or edit a [Note].
///
/// Pass [moduleId] to create a brand new note inside that module, or pass
/// an existing [note] to edit it in place.
class NoteEditorScreen extends StatefulWidget {
  final String? moduleId;
  final Note? note;

  const NoteEditorScreen({super.key, this.moduleId, this.note})
      : assert(moduleId != null || note != null,
            'Either moduleId (new note) or note (edit) must be provided.');

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled note'
        : _titleController.text.trim();
    final content = _contentController.text;

    if (_isEditing) {
      await DatabaseHelper.updateNote(widget.note!, title: title, content: content);
    } else {
      await DatabaseHelper.addNote(widget.moduleId!, title: title, content: content);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.sidebarBackground,
        title: const Text("Delete Note", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this note?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.deleteNote(widget.note!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: Text(_isEditing ? "Edit Note" : "New Note"),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: !_isEditing,
              style: AppTextStyles.header,
              decoration: const InputDecoration(
                hintText: "Note title",
                hintStyle: TextStyle(color: AppColors.textDisabled),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _contentController,
                style: AppTextStyles.body,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: "Write your note here…",
                  hintStyle: TextStyle(color: AppColors.textDisabled),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
