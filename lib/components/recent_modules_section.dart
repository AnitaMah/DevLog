import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/components/recent_module_card.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Віджет для відображення секції "Continue where you left off".
/// Показує модулі, які були відкриті протягом останніх 24 годин.
class RecentModulesSection extends StatelessWidget {
  const RecentModulesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final Box<Module> modulesBox = Hive.box<Module>('modules');

    return ValueListenableBuilder<Box<Module>>(
      valueListenable: modulesBox.listenable(),
      builder: (context, box, _) {
        final recentModules = box.values
            .where((module) => DateTime.now().difference(module.getLastOpenedAt()).inHours < 24)
            .toList()
          ..sort((a, b) => b.getLastOpenedAt().compareTo(a.getLastOpenedAt()));

        if (recentModules.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                "Continue where you left off",
                style: AppTextStyles.title,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: recentModules.length,
                itemBuilder: (context, index) {
                  final module = recentModules[index];
                  return Padding(
                    padding: EdgeInsets.only(right: index == recentModules.length - 1 ? 0 : AppSpacing.md),
                    child: RecentModuleCard(
                      module: module,
                      onTap: () {
                        module.updateLastOpenedAt();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}