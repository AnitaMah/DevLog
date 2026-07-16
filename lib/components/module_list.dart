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
              child: Text('No modules yet. Add one!', style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: box.length,
          itemBuilder: (context, index) {
            final module = box.getAt(index);
            if (module == null) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => ModuleInputDialog(module: module, isEditing: true),
                ),
                title: Text(module.title, style: AppTextStyles.cardTitle),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("${module.notesCount} notes", style: AppTextStyles.cardSubtitle),
                    const SizedBox(height: 8),
                    // Відображення прогресу
                    LinearProgressIndicator(
                      value: module.progress,
                      backgroundColor: Colors.white10,
                      color: AppColors.accentPurple,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white54),
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
        title: const Text("Delete Module"),
        content: Text("Are you sure you want to delete '${module.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              module.delete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}