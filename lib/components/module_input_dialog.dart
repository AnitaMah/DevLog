import 'package:flutter/material.dart';
import 'package:dev_log/components/app_icon_button.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/helpers/id_generator.dart';
import 'package:dev_log/helpers/project_status.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Dialog used both to create a new module (or submodule, via [parentId])
/// and to edit an existing one (pass [module] with [isEditing] true).
class ModuleInputDialog extends StatefulWidget {
  final Module? module;
  final String? parentId;
  final bool isEditing;

  /// Pre-checks "This is a project" when creating a new module (ignored
  /// when [isEditing] - an existing module's own value wins instead) - lets
  /// the Projects screen's "+ New project" button skip the extra toggle.
  final bool initialIsProject;

  const ModuleInputDialog({
    super.key,
    this.module,
    this.parentId,
    this.isEditing = false,
    this.initialIsProject = false,
  });

  @override
  State<ModuleInputDialog> createState() => _ModuleInputDialogState();
}

class _ModuleInputDialogState extends State<ModuleInputDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _repoUrlController;
  late String _selectedIcon;
  late bool _isProject;
  late String _status;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.module?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.module?.description ?? '');
    _repoUrlController = TextEditingController(text: widget.module?.repoUrl ?? '');
    _selectedIcon = widget.module?.iconName ?? 'folder';
    _isProject = widget.module?.isProject ?? widget.initialIsProject;
    _status = widget.module?.status ?? 'in_progress';
    _deadline = widget.module?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _repoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final repoUrl = _repoUrlController.text.trim();

    if (widget.isEditing && widget.module != null) {
      final module = widget.module!;
      module.title = title;
      module.description = _descriptionController.text.trim();
      module.iconName = _selectedIcon;
      module.isProject = _isProject;
      module.status = _status;
      module.repoUrl = repoUrl.isEmpty ? null : repoUrl;
      module.deadline = _deadline;
      await DatabaseHelper.updateModule(module);
    } else {
      final newModule = Module(
        id: generateId(),
        title: title,
        description: _descriptionController.text.trim(),
        iconName: _selectedIcon,
        parentId: widget.parentId,
        isProject: _isProject,
        status: _status,
        repoUrl: repoUrl.isEmpty ? null : repoUrl,
        deadline: _deadline,
      );
      await DatabaseHelper.addModule(newModule);
    }

    if (mounted) Navigator.pop(context);
  }

  List<Widget> _buildProjectFields() {
    return [
      const SizedBox(height: AppSpacing.md),
      DropdownButtonFormField<String>(
        initialValue: _status,
        decoration: const InputDecoration(labelText: "Status"),
        style: TextStyle(color: AppColors.textPrimary),
        dropdownColor: AppColors.sidebarBackground,
        items: projectStatusLabels.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _status = value);
        },
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _repoUrlController,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(labelText: "Repo URL (optional)"),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: Text(
              _deadline == null
                  ? "No deadline"
                  : "Deadline: ${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: _pickDeadline,
            child: Text(_deadline == null ? "Set" : "Change"),
          ),
          if (_deadline != null)
            AppIconButton(
              icon: Icons.close,
              onPressed: () => setState(() => _deadline = null),
            ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.sidebarBackground,
      title: Text(
        widget.isEditing ? "Edit Module" : "Add Module",
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text("Icon", style: AppTextStyles.cardSubtitle),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IconHelper.icons.keys.map((name) {
                final selected = name == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = name),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: IconHelper.getFaIcon(
                      name,
                      size: 16,
                      color: selected ? AppColors.accentOnColor : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("This is a project", style: TextStyle(color: AppColors.textPrimary)),
              value: _isProject,
              onChanged: (value) => setState(() => _isProject = value),
            ),
            if (_isProject) ..._buildProjectFields(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: _save,
          child: Text(widget.isEditing ? "Save" : "Add"),
        ),
      ],
    );
  }
}
