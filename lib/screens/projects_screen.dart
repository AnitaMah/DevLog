import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/components/project_hero_card.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Projects tab: every module marked as a project, as [ProjectHeroCard]s.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, Box<Module> box, _) {
        final projects = DatabaseHelper.getProjects();

        if (projects.isEmpty) {
          return Center(
            child: Text(
              "No projects yet. Mark a module as a project from its edit dialog.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDisabled),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.xl),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) => ProjectHeroCard(module: projects[index]),
        );
      },
    );
  }
}
