import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/database/database_helper.dart';

/// Shows your modules as colored tag chips sized/sorted by note count,
/// standing in for a dedicated tag system (which the data model doesn't
/// have yet — each "tag" here is really a top-level module).
class PopularTagsPanel extends StatelessWidget {
  const PopularTagsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Module>>(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, moduleBox, _) {
        return ValueListenableBuilder<Box<Note>>(
          valueListenable: Hive.box<Note>('notes').listenable(),
          builder: (context, _, _) {
            final modules = moduleBox.values.where((m) => m.parentId == null).toList()
              ..sort((a, b) => DatabaseHelper.getNotesCountForModule(b.id)
                  .compareTo(DatabaseHelper.getNotesCountForModule(a.id)));

            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Popular Tags", style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.md),
                  if (modules.isEmpty)
                    const Text("No modules yet.", style: AppTextStyles.smallText)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: modules.map((module) {
                        final color = AppColors.tagColorFor(module.title);
                        final count = DatabaseHelper.getNotesCountForModule(module.id);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: color.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            "${module.title}  $count",
                            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
