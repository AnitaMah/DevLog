import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/components/project_hero_card.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Projects tab: every module marked as a project, as [ProjectHeroCard]s -
/// matches the Terminal Dark + Spatial mockup's "~/projects" page (header,
/// "+ New project" action, glass card grid).
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, Box<Module> box, _) {
        final projects = DatabaseHelper.getProjects();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(48, 40, 48, 56),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '~/projects',
                            style: AppTextStyles.mono.copyWith(color: AppColors.accent),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text("Projects", style: AppTextStyles.header),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            "Tasks with deadlines and checklists, separate from notes.",
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    LiquidSheen(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: ElevatedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => const ModuleInputDialog(initialIsProject: true),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.accentOnColor,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("New project"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (projects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Text(
                      "No projects yet. Mark a module as a project from its edit dialog, or create one above.",
                      style: TextStyle(color: AppColors.textDisabled),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.6,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) => ProjectHeroCard(module: projects[index]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
