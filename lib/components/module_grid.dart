import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: modules.length + 1,
          itemBuilder: (context, index) {
            if (index == modules.length) {
              return const AddModuleCard();
            }

            final module = modules[index];

            return Stack(
              children: [
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => ModuleInputDialog(
                      module: module,
                      isEditing: true,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconHelper.getFaIcon(
                          module.iconName,
                          size: 32,
                          color: AppColors.accentPurple,
                        ),
                        const Spacer(),
                        Text(
                          module.title,
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${module.notesCount} notes",
                          style: AppTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white54,
                    ),
                    onPressed: () => _showDeleteConfirmationDialog(
                      context,
                      module,
                      box,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    Module module,
    Box<Module> box,
  ) {
    final submodulesCount = box.values
        .where((m) => m.parentId == module.id)
        .length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Module"),
        content: Text(
          submodulesCount > 0
              ? "Are you sure you want to delete '${module.title}'? This will also delete $submodulesCount submodules and ${module.notesCount} notes."
              : "Are you sure you want to delete '${module.title}'? This will delete ${module.notesCount} notes.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _deleteModuleAndSubmodules(module, box);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

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