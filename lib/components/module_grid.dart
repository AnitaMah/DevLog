import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/components/add_module_card.dart';
import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/helpers/module_actions.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/screens/module_details_screen.dart';

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
              ...modules.map((m) => _buildCard(context, m)),
              const SizedBox(width: 220, child: AddModuleCard()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, Module module) {
    // Material (not a decorated Container) so the InkWell's tap ripple has
    // a Material ancestor to paint on without an opaque box in the way.
    return SizedBox(
      width: 220,
      child: Material(
        color: AppColors.cardBackground,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        child: Stack(
          children: [
            InkWell(
              onTap: () {
                module.updateLastOpenedAt();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ModuleDetailsScreen(module: module)),
                );
              },
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
                          ValueListenableBuilder<Box<Note>>(
                            valueListenable: Hive.box<Note>('notes').listenable(),
                            builder: (context, _, _) => Text(
                              "${DatabaseHelper.getNotesCountForModule(module.id)} notes",
                              style: AppTextStyles.cardSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.edit_outlined, size: 14, color: AppColors.textDisabled),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (c) => ModuleInputDialog(module: module, isEditing: true),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close, size: 14, color: AppColors.textDisabled),
                    onPressed: () => confirmAndDeleteModule(context, module),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}