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
  final TextEditingController _tagController = TextEditingController();
  late List<String> _tags;
  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tags = List<String>.from(widget.note?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final tag = raw.trim();
    setState(() {
      if (tag.isNotEmpty && !_tags.contains(tag)) {
        _tags.add(tag);
      }
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled note'
        : _titleController.text.trim();
    final content = _contentController.text;

    if (_isEditing) {
      await DatabaseHelper.updateNote(widget.note!, title: title, content: content, tags: _tags);
    } else {
      await DatabaseHelper.addNote(widget.moduleId!, title: title, content: content, tags: _tags);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.sidebarBackground,
        title: Text("Delete Note", style: TextStyle(color: AppColors.textPrimary)),
        content: Text("Are you sure you want to delete this note?",
            style: TextStyle(color: AppColors.textSecondary)),
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
              decoration: InputDecoration(
                hintText: "Note title",
                hintStyle: TextStyle(color: AppColors.textDisabled),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTagEditor(),
            const SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.divider),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _contentController,
                style: AppTextStyles.body,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
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

  Widget _buildTagEditor() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tag in _tags)
          Chip(
            label: Text(tag, style: TextStyle(color: AppColors.tagColorFor(tag), fontSize: 12)),
            backgroundColor: AppColors.tagColorFor(tag).withValues(alpha: 0.15),
            side: BorderSide(color: AppColors.tagColorFor(tag).withValues(alpha: 0.4)),
            deleteIcon: Icon(Icons.close, size: 14, color: AppColors.tagColorFor(tag)),
            onDeleted: () => _removeTag(tag),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _tagController,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            decoration: InputDecoration(
              hintText: "+ add tag",
              hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 12),
              isDense: true,
              border: InputBorder.none,
            ),
            onSubmitted: _addTag,
          ),
        ),
      ],
    );
  }
}
