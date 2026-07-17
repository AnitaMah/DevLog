import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dev_log/models/module.dart';

class AddModuleDialog extends StatefulWidget {
  final String? parentId;
  const AddModuleDialog({super.key, this.parentId});

  @override
  State<AddModuleDialog> createState() => _AddModuleDialogState();
}

class _AddModuleDialogState extends State<AddModuleDialog> {
  final _controller = TextEditingController();

  void _save() {
    final newModule = Module(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _controller.text,
      parentId: widget.parentId, // Зв'язок із батьком
    );
    Hive.box<Module>('modules').add(newModule);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Module"),
      content: TextField(controller: _controller),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: _save, child: const Text("Save")),
      ],
    );
  }
}
