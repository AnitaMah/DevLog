import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/theme/app_theme.dart';

class ModuleList extends StatelessWidget {
  const ModuleList({super.key});

  @override
  Widget build(BuildContext context) {
    final Box<Module> modulesBox = Hive.box<Module>('modules');

    return ValueListenableBuilder<Box<Module>>(
      valueListenable: modulesBox.listenable(),
      builder: (context, box, _) {
        if (box.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text('No modules yet.', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Використовуйте з SingleChildScrollView в Sidebar
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: box.length,
          itemBuilder: (context, index) {
            final module = box.getAt(index);
            if (module == null) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground, // Темний фон картки[cite: 7]
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                dense: true,
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => ModuleInputDialog(module: module, isEditing: true),
                ),
                title: Text(module.title, style: AppTextStyles.cardTitle),
                subtitle: Text("${module.notesCount} notes", style: AppTextStyles.cardSubtitle),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 14, color: Colors.white30),
                  onPressed: () => _showDeleteConfirmationDialog(context, module),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Module module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.sidebarBackground, // Відповідний темний фон[cite: 7]
        title: const Text("Delete Module", style: TextStyle(color: Colors.white)),
        content: Text("Delete '${module.title}'?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.white54))
          ),
          TextButton(
            onPressed: () {
              module.delete(); // Логіка видалення
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}