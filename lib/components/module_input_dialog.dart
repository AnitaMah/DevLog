import 'package:flutter/material.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';

class ModuleInputDialog extends StatefulWidget {
  const ModuleInputDialog({super.key});

  @override
  State<ModuleInputDialog> createState() => _ModuleInputDialogState();
}

class _ModuleInputDialogState extends State<ModuleInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final moduleName = _controller.text.trim();
    if (moduleName.isNotEmpty) {
      final newModule = Module(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: moduleName,
      );
      DatabaseHelper.addModule(newModule);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Module"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: "Module Name",
          hintText: "Enter module name",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: _save,
          child: const Text("Add"),
        ),
      ],
    );
  }
}
