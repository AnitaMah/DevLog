// lib/screens/module_details_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/module_input_dialog.dart';
// Припускаємо, що у вас є файл з цим віджетом
import 'package:dev_log/components/module_tile.dart'; 

class ModuleDetailsScreen extends StatelessWidget {
  final Module module;

  const ModuleDetailsScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(module.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentPurple,
        onPressed: () => showDialog(
          context: context,
          builder: (_) => ModuleInputDialog(parentId: module.id, isEditing: false),
        ),
        label: const Text("Add Submodule"),
        icon: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Module>('modules').listenable(),
        builder: (context, Box<Module> box, _) {
          // Фільтруємо підмодулі
          final subModules = box.values.where((m) => m.parentId == module.id).toList();
          
          if (subModules.isEmpty) {
            return const Center(
              child: Text("No submodules yet. Add one!", style: TextStyle(color: Colors.white30))
            );
          }

          // Використовуємо GridView для відображення карток підмодулів
          return GridView.builder(
            padding: const EdgeInsets.all(32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5, // Адаптуйте під розмір вашої картки
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: subModules.length,
            itemBuilder: (context, index) {
              final sub = subModules[index];
              // Використовуємо ваш існуючий ModuleTile, щоб дизайн збігався
              return ModuleTile(module: sub); 
            },
          );
        },
      ),
    );
  }
}
