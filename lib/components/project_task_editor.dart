import 'package:flutter/material.dart';

import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/project_task.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Inline checklist editor for a project [Module]'s [Module.tasks], styled
/// as the Terminal Dark + Spatial mockup's project-detail checklist: a
/// glass panel of hoverable rows with pill checkboxes and a drag handle,
/// plus an "add item" row. Every add/toggle/remove/edit/reorder persists
/// immediately via [DatabaseHelper.updateModule] - there's no separate
/// "Save" step, unlike the note editor's tag field.
class ProjectTaskEditor extends StatefulWidget {
  final Module module;

  const ProjectTaskEditor({super.key, required this.module});

  @override
  State<ProjectTaskEditor> createState() => _ProjectTaskEditorState();
}

class _ProjectTaskEditorState extends State<ProjectTaskEditor> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();
  ProjectTask? _editingTask;

  @override
  void dispose() {
    _taskController.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addTask(String raw) async {
    final title = raw.trim();
    if (title.isEmpty) return;
    setState(() {
      widget.module.tasks.add(ProjectTask(title: title));
      _taskController.clear();
    });
    await DatabaseHelper.updateModule(widget.module);
  }

  Future<void> _toggleTask(ProjectTask task) async {
    setState(() => task.done = !task.done);
    await DatabaseHelper.updateModule(widget.module);
  }

  Future<void> _removeTask(ProjectTask task) async {
    setState(() {
      widget.module.tasks.remove(task);
      if (_editingTask == task) _editingTask = null;
    });
    await DatabaseHelper.updateModule(widget.module);
  }

  void _startEditing(ProjectTask task) {
    setState(() {
      _editingTask = task;
      _editController.text = task.title;
    });
    _editFocusNode.requestFocus();
  }

  Future<void> _commitEdit() async {
    final task = _editingTask;
    if (task == null) return;
    final title = _editController.text.trim();
    setState(() {
      if (title.isNotEmpty) task.title = title;
      _editingTask = null;
    });
    await DatabaseHelper.updateModule(widget.module);
  }

  Future<void> _reorderTask(int oldIndex, int newIndex) async {
    setState(() {
      final task = widget.module.tasks.removeAt(oldIndex);
      widget.module.tasks.insert(newIndex, task);
    });
    await DatabaseHelper.updateModule(widget.module);
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: widget.module.tasks.length,
              onReorderItem: _reorderTask,
              itemBuilder: (context, index) {
                final task = widget.module.tasks[index];
                return _TaskRow(
                  key: ValueKey(task),
                  task: task,
                  index: index,
                  isEditing: _editingTask == task,
                  editController: _editController,
                  editFocusNode: _editFocusNode,
                  onToggle: () => _toggleTask(task),
                  onStartEditing: () => _startEditing(task),
                  onCommitEdit: _commitEdit,
                  onRemove: () => _removeTask(task),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: AppColors.textDisabled),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: "Add item…",
                        hintStyle: TextStyle(color: AppColors.textDisabled),
                      ),
                      onSubmitted: _addTask,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// A single checklist row: pill checkbox, title (editable on tap), drag
/// handle, remove action - lightly highlighted on hover like the mockup's
/// `.task-row:hover` state.
class _TaskRow extends StatefulWidget {
  final ProjectTask task;
  final int index;
  final bool isEditing;
  final TextEditingController editController;
  final FocusNode editFocusNode;
  final VoidCallback onToggle;
  final VoidCallback onStartEditing;
  final VoidCallback onCommitEdit;
  final VoidCallback onRemove;

  const _TaskRow({
    super.key,
    required this.task,
    required this.index,
    required this.isEditing,
    required this.editController,
    required this.editFocusNode,
    required this.onToggle,
    required this.onStartEditing,
    required this.onCommitEdit,
    required this.onRemove,
  });

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: _hovering ? AppColors.cardBackground : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: widget.index,
              child: Icon(Icons.drag_indicator, size: 16, color: AppColors.textDisabled),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: widget.onToggle,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.task.done ? AppColors.accent : Colors.transparent,
                  border: Border.all(
                    color: widget.task.done ? AppColors.accent : AppColors.cardBorder,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: widget.task.done
                    ? Icon(Icons.check, size: 14, color: AppColors.accentOnColor)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: widget.isEditing
                  ? TextField(
                      controller: widget.editController,
                      focusNode: widget.editFocusNode,
                      autofocus: true,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                      onSubmitted: (_) => widget.onCommitEdit(),
                      onEditingComplete: widget.onCommitEdit,
                      onTapOutside: (_) => widget.onCommitEdit(),
                    )
                  : GestureDetector(
                      onTap: widget.onStartEditing,
                      child: Text(
                        widget.task.title,
                        style: TextStyle(
                          color: widget.task.done ? AppColors.textDisabled : AppColors.textPrimary,
                          fontSize: 14,
                          decoration: widget.task.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
            ),
            if (_hovering)
              GestureDetector(
                onTap: widget.onRemove,
                child: Icon(Icons.close, size: 16, color: AppColors.textDisabled),
              ),
          ],
        ),
      ),
    );
  }
}
