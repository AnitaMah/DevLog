import 'package:flutter/material.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Dialog used both to create a new module (or submodule, via [parentId])
/// and to edit an existing one (pass [module] with [isEditing] true).
class ModuleInputDialog extends StatefulWidget {
  final Module? module;
  final String? parentId;
  final bool isEditing;

  const ModuleInputDialog({
    super.key,
    this.module,
    this.parentId,
    this.isEditing = false,
  });

  @override
  State<ModuleInputDialog> createState() => _ModuleInputDialogState();
}

class _ModuleInputDialogState extends State<ModuleInputDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.module?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.module?.description ?? '');
    _selectedIcon = widget.module?.iconName ?? 'folder';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    if (widget.isEditing && widget.module != null) {
      final module = widget.module!;
      module.title = title;
      module.description = _descriptionController.text.trim();
      module.iconName = _selectedIcon;
      await DatabaseHelper.updateModule(module);
    } else {
      final newModule = Module(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: _descriptionController.text.trim(),
        iconName: _selectedIcon,
        parentId: widget.parentId,
      );
      await DatabaseHelper.addModule(newModule);
    }

    if (mounted) Navigator.pop(context);
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
                          ? AppColors.accentPurple
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: IconHelper.getFaIcon(
                      name,
                      size: 16,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
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
