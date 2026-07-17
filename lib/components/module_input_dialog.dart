import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dev_log/theme/app_theme.dart'; // Імпортуємо для кольорів

class ModuleInputDialog extends StatefulWidget {
  final Module? module;
  final bool isEditing;
  final bool isSubModule;

  const ModuleInputDialog({
    super.key,
    this.module,
    this.isEditing = false,
    this.isSubModule = false,
  });

  @override
  State<ModuleInputDialog> createState() => _ModuleInputDialogState();
}

class _ModuleInputDialogState extends State<ModuleInputDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedFilePath;
  String _selectedIcon = 'code';

  final List<String> _availableIcons = IconHelper.icons.keys.toList();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.module?.title ?? "";
    _descriptionController.text = widget.module?.description ?? "";
    _selectedFilePath = widget.module?.filePath;
    _selectedIcon = widget.module?.iconName ?? 'code';
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => _selectedFilePath = result.files.single.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.sidebarBackground, // Темний фон діалогу
      title: Text(widget.isEditing ? "Edit Module" : "Add Module", 
                  style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Title", 
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Description", 
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 20),

            // Icon selection
            DropdownButtonFormField<String>(
              value: _selectedIcon,
              dropdownColor: AppColors.sidebarBackground,
              isExpanded: true,
              items: _availableIcons.map((icon) {
                return DropdownMenuItem<String>(
                  value: icon,
                  child: Row(
                    children: [
                      IconHelper.getFaIcon(icon, size: 18, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(icon, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedIcon = val!),
              decoration: const InputDecoration(
                labelText: "Icon", 
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),

            // File picker
            if (widget.isSubModule)
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file, color: AppColors.accentPurple),
                label: Text(
                  _selectedFilePath == null ? "Attach File" : "File Selected",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPurple),
          child: const Text("Save"),
        ),
      ],
    );
  }

  void _submit() {
    final box = Hive.box<Module>('modules');
    if (widget.isEditing && widget.module != null) {
      widget.module!.title = _titleController.text;
      widget.module!.description = _descriptionController.text;
      widget.module!.filePath = _selectedFilePath;
      widget.module!.iconName = _selectedIcon;
      widget.module!.save();
    } else {
      box.add(
        Module(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          notesCount: 0,
          filePath: _selectedFilePath,
          iconName: _selectedIcon,
          parentId: widget.isSubModule ? widget.module?.id : null,
        ),
      );
    }
    Navigator.pop(context);
  }
}