import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/components/add_module_card.dart';
import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/helpers/icon_helper.dart';

class ModuleGrid extends StatelessWidget {
  const ModuleGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, Box<Module> box, _) {
        final modules = box.values.where((m) => m.parentId == null).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...modules.map((m) => _buildCard(context, m, box)),
              const SizedBox(width: 220, child: AddModuleCard()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, Module module, Box<Module> box) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () => showDialog(
              context: context, 
              builder: (c) => ModuleInputDialog(module: module, isEditing: true)
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconHelper.getFaIcon(module.iconName, size: 20, color: AppColors.accentPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(module.title, style: AppTextStyles.cardTitle, overflow: TextOverflow.ellipsis),
                        Text("${module.notesCount} notes", style: AppTextStyles.cardSubtitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, size: 14, color: Colors.white30),
              onPressed: () => _showDeleteConfirmationDialog(context, module, box),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Module module, Box<Module> box) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Module"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              _deleteModuleAndSubmodules(module, box);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Збережена функція видалення
  void _deleteModuleAndSubmodules(Module module, Box<Module> box) {
    final submodules = box.values
        .where((m) => m.parentId == module.id)
        .toList();

    for (final submodule in submodules) {
      _deleteModuleAndSubmodules(submodule, box);
    }

    module.delete();
  }
}