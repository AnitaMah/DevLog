import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';

/// A point-in-time snapshot of the editor's title/content/tags, used by the
/// undo/redo stack.
class _EditorSnapshot {
  final String title;
  final String content;
  final List<String> tags;

  _EditorSnapshot(this.title, this.content, List<String> tags) : tags = List.unmodifiable(tags);
}

bool _snapshotsEqual(_EditorSnapshot a, _EditorSnapshot b) =>
    a.title == b.title && a.content == b.content && listEquals(a.tags, b.tags);

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

  // Fed nothing on purpose: TextField's own built-in Ctrl/Cmd+Z handling
  // always consumes the keystroke before our screen-level CallbackShortcuts
  // sees it, even when there's nothing for the field itself to undo. Giving
  // each field this permanently-empty controller makes Flutter report that
  // built-in undo/redo as disabled, so the key event falls through to our
  // combined undo/redo stack below instead.
  final UndoHistoryController _disabledFieldUndo = UndoHistoryController();

  // The persisted note backing this screen. Starts out as widget.note when
  // editing, or null for a brand-new note until the first autosave (or an
  // explicit save) creates it - after that, autosave and save both update
  // this same record instead of creating duplicates.
  Note? _note;

  Timer? _autosaveTimer;
  bool _autosaving = false;
  static const _autosaveDelay = Duration(seconds: 2);

  // Undo/redo, scoped to this screen's lifetime (not persisted). Rapid
  // keystrokes are grouped into one undo step by only recording a new
  // checkpoint once typing has paused for [_checkpointDelay] - otherwise
  // undo would revert one character at a time.
  final List<_EditorSnapshot> _undoStack = [];
  final List<_EditorSnapshot> _redoStack = [];
  late _EditorSnapshot _lastCheckpoint;
  Timer? _checkpointTimer;
  bool _applyingHistory = false;
  static const _checkpointDelay = Duration(milliseconds: 800);

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  // Snapshot of the last-saved (or initial) state, used to detect unsaved
  // changes when the user tries to leave the screen.
  late String _initialTitle;
  late String _initialContent;
  late List<String> _initialTags;

  // Set right before an intentional pop (after saving or deleting, or when
  // the user explicitly chooses to discard changes) so the unsaved-changes
  // guard doesn't block that pop.
  bool _bypassUnsavedGuard = false;

  bool get _hasUnsavedChanges {
    if (_bypassUnsavedGuard) return false;
    return _titleController.text != _initialTitle ||
        _contentController.text != _initialContent ||
        !listEquals(_tags, _initialTags) ||
        // Text typed into the tag box isn't a tag until Enter is pressed -
        // without this, typing a tag and then hitting the save button (or
        // Ctrl+S, or closing the window) would silently drop it with no
        // unsaved-changes warning at all.
        _tagController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tags = List<String>.from(widget.note?.tags ?? []);
    _initialTitle = _titleController.text;
    _initialContent = _contentController.text;
    _initialTags = List<String>.from(_tags);
    _lastCheckpoint = _snapshotNow();
    _titleController.addListener(_scheduleAutosave);
    _titleController.addListener(_scheduleCheckpoint);
    _contentController.addListener(_scheduleAutosave);
    _contentController.addListener(_scheduleCheckpoint);
  }

  /// Pops the screen once the current frame has rebuilt with the updated
  /// unsaved-changes state, so PopScope's `canPop` is guaranteed to reflect
  /// the change before the pop is attempted.
  void _popWhenClean() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _checkpointTimer?.cancel();
    _disabledFieldUndo.dispose();
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
    _scheduleAutosave();
    _scheduleCheckpoint();
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    _scheduleAutosave();
    _scheduleCheckpoint();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDelay, _autosave);
  }

  _EditorSnapshot _snapshotNow() =>
      _EditorSnapshot(_titleController.text, _contentController.text, _tags);

  void _scheduleCheckpoint() {
    if (_applyingHistory) return;
    _checkpointTimer?.cancel();
    _checkpointTimer = Timer(_checkpointDelay, _commitCheckpoint);
  }

  /// Records the gap between [_lastCheckpoint] and the current state as one
  /// undo step, if anything actually changed.
  void _commitCheckpoint() {
    final current = _snapshotNow();
    if (_snapshotsEqual(current, _lastCheckpoint)) return;
    setState(() {
      _undoStack.add(_lastCheckpoint);
      _redoStack.clear();
      _lastCheckpoint = current;
    });
  }

  void _undo() {
    _checkpointTimer?.cancel();
    // Flush whatever was typed since the last checkpoint into its own step
    // first, so undo always reverts exactly one coherent edit.
    _commitCheckpoint();
    if (_undoStack.isEmpty) return;
    final target = _undoStack.removeLast();
    _redoStack.add(_lastCheckpoint);
    _applyHistory(target);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final target = _redoStack.removeLast();
    _undoStack.add(_lastCheckpoint);
    _applyHistory(target);
  }

  void _applyHistory(_EditorSnapshot snapshot) {
    _applyingHistory = true;
    setState(() {
      _titleController.text = snapshot.title;
      _contentController.text = snapshot.content;
      _tags = List<String>.from(snapshot.tags);
      _lastCheckpoint = snapshot;
    });
    _applyingHistory = false;
    _scheduleAutosave();
  }

  /// Writes the current title/content/tags to [_note], creating it first if
  /// this is a still-unsaved new note.
  Future<void> _persist({required String title, required String content}) async {
    if (_note != null) {
      await DatabaseHelper.updateNote(_note!, title: title, content: content, tags: _tags);
    } else {
      _note = await DatabaseHelper.addNote(widget.moduleId!, title: title, content: content, tags: _tags);
    }
  }

  /// Silent debounced write - no navigation, no dialogs. Skipped while a
  /// save/autosave is already in flight or if nothing has changed since the
  /// last persisted state, so it never fights with an explicit save.
  Future<void> _autosave() async {
    if (!mounted || _autosaving) return;
    final title = _titleController.text;
    final content = _contentController.text;
    if (title.trim().isEmpty && content.isEmpty && _tags.isEmpty) return;
    if (title == _initialTitle && content == _initialContent && listEquals(_tags, _initialTags)) {
      return;
    }

    _autosaving = true;
    try {
      final resolvedTitle = title.trim().isEmpty ? 'Untitled note' : title.trim();
      await _persist(title: resolvedTitle, content: content);
      if (!mounted) return;
      setState(() {
        _initialTitle = resolvedTitle;
        _initialContent = content;
        _initialTags = List<String>.from(_tags);
      });
    } finally {
      _autosaving = false;
    }
  }

  Future<void> _save() async {
    _autosaveTimer?.cancel();

    // Commit any tag text still sitting in the input box (typed but never
    // confirmed with Enter) so saving doesn't silently drop it.
    final pendingTag = _tagController.text.trim();
    if (pendingTag.isNotEmpty && !_tags.contains(pendingTag)) {
      _tags.add(pendingTag);
    }
    _tagController.clear();

    final title = _titleController.text.trim().isEmpty
        ? 'Untitled note'
        : _titleController.text.trim();
    final content = _contentController.text;

    await _persist(title: title, content: content);

    if (!mounted) return;
    setState(() {
      _initialTitle = title;
      _initialContent = content;
      _initialTags = List<String>.from(_tags);
    });
    _popWhenClean();
  }

  Future<void> _delete() async {
    _autosaveTimer?.cancel();
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
      await DatabaseHelper.deleteNote(_note!.id);
      if (!mounted) return;
      setState(() => _bypassUnsavedGuard = true);
      _popWhenClean();
    }
  }

  Future<String?> _showUnsavedChangesDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.sidebarBackground,
        title: Text("Unsaved changes", style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          "You have unsaved changes to this note. Save before leaving?",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text("Discard", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): _save,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): _save,
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): _undo,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ): _undo,
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): _redo,
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): _redo,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): _redo,
      },
      child: PopScope(
        canPop: !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final choice = await _showUnsavedChangesDialog();
          if (!mounted) return;
          if (choice == 'save') {
            await _save();
          } else if (choice == 'discard') {
            setState(() => _bypassUnsavedGuard = true);
            _popWhenClean();
          }
        },
        // CallbackShortcuts only fires when some descendant already holds
        // keyboard focus. New notes get that for free from the title
        // field's own autofocus below; editing an existing note doesn't
        // autofocus anything, so Ctrl/Cmd+S would silently do nothing until
        // the user clicked into a field - this covers that gap.
        child: Focus(
          autofocus: _isEditing,
          child: _buildScaffold(),
        ),
      ),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: Text(_isEditing ? "Edit Note" : "New Note"),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _canUndo ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: _canRedo ? _redo : null,
          ),
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
              undoController: _disabledFieldUndo,
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
                undoController: _disabledFieldUndo,
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
