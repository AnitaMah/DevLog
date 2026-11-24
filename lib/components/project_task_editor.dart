import 'package:flutter/material.dart';

import 'package:dev_log/components/app_icon_button.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/project_task.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Inline checklist editor for a project [Module]'s [Module.tasks]. Every
/// add/toggle/remove/edit/reorder persists immediately via
/// [DatabaseHelper.updateModule] - there's no separate "Save" step, unlike
/// the note editor's tag field.
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

  Future<void> _toggleTask(ProjectTask task, bool? value) async {
    setState(() => task.done = value ?? false);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tasks", style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.md),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: widget.module.tasks.length,
          onReorderItem: _reorderTask,
          itemBuilder: (context, index) {
            final task = widget.module.tasks[index];
            final isEditing = _editingTask == task;
            return Padding(
              key: ValueKey(task),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Checkbox(
                    value: task.done,
                    onChanged: (value) => _toggleTask(task, value),
                  ),
                  Expanded(
                    child: isEditing
                        ? TextField(
                            controller: _editController,
                            focusNode: _editFocusNode,
                            autofocus: true,
                            style: TextStyle(color: AppColors.textPrimary),
                            onSubmitted: (_) => _commitEdit(),
                            onEditingComplete: _commitEdit,
                            onTapOutside: (_) => _commitEdit(),
                          )
                        : GestureDetector(
                            onTap: () => _startEditing(task),
                            child: Text(
                              task.title,
                              style: TextStyle(
                                color: task.done ? AppColors.textDisabled : AppColors.textPrimary,
                                decoration: task.done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                  ),
                  AppIconButton(
                    icon: Icons.close,
                    onPressed: () => _removeTask(task),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.drag_handle, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _taskController,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: "+ add task"),
                onSubmitted: _addTask,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, color: AppColors.textSecondary),
              onPressed: () => _addTask(_taskController.text),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
