import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/module_input_dialog.dart';
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
          // Фільтруємо модулі, щоб показати тільки ті, у яких parentId збігається з поточним
          final subModules = box.values.where((m) => m.parentId == module.id).toList();
          
          if (subModules.isEmpty) {
            return const Center(
              child: Text("No submodules yet. Click below to add one!", 
              style: TextStyle(color: Colors.white30))
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: subModules.length,
            itemBuilder: (context, index) {
              final sub = subModules[index];
              return ModuleTile(module: sub); // Використовуємо вашу картку
            },
          );
        },
      ),
    );
  }
}
