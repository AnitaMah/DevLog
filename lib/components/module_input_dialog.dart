import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/theme/app_theme.dart';

void showModuleRenameDialog(BuildContext context, Module module, int index) {
  final controller = TextEditingController(text: module.title);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.sidebarBackground,
      title: const Text("Rename Module", style: AppTextStyles.header),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: "Enter name",
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentPurple),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final box = Hive.box<Module>('modules');
            // Оновлюємо модуль, передаючи ВСІ обов'язкові параметри
            box.putAt(index, Module(
              id: module.id,
              title: controller.text,
              description: module.description, // ВИПРАВЛЕНО: Додано обов'язковий параметр
              notesCount: module.notesCount,
            ));
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}