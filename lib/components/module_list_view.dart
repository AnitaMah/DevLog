import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/database/database_helper.dart';

/// Row-based alternative to [ModuleGrid], toggled from the dashboard's
/// grid/list view switch.
class ModuleListView extends StatelessWidget {
  const ModuleListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, Box<Module> box, _) {
        final modules = box.values.where((m) => m.parentId == null).toList();

        return Column(
          children: modules
              .map((module) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: ListTile(
                        leading: IconHelper.getFaIcon(module.iconName,
                            size: 18, color: AppColors.accentPurple),
                        title: Text(module.title, style: AppTextStyles.cardTitle),
                        subtitle: ValueListenableBuilder<Box<Note>>(
                          valueListenable: Hive.box<Note>('notes').listenable(),
                          builder: (context, _, _) => Text(
                            "${DatabaseHelper.getNotesCountForModule(module.id)} notes",
                            style: AppTextStyles.cardSubtitle,
                          ),
                        ),
                        onTap: () => showDialog(
                          context: context,
                          builder: (c) => ModuleInputDialog(module: module, isEditing: true),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 14, color: Colors.white30),
                          onPressed: () => DatabaseHelper.deleteModule(module.id),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
