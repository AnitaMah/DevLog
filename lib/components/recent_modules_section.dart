import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/components/recent_module_card.dart';

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
        // Фільтруємо модулі, які були відкриті протягом останніх 24 годин
        final recentModules = box.values
            .where((module) {
              final lastOpened = module.getLastOpenedAt();
              final now = DateTime.now();
              return now.difference(lastOpened).inHours < 24;
            })
            .toList()
          // Сортуємо за часом останнього відкриття (новіші першими)
          ..sort((a, b) => b.getLastOpenedAt().compareTo(a.getLastOpenedAt()));

        // Якщо немає недавніх модулів, не показуємо секцію
        if (recentModules.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок секції
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Continue where you left off",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // Список недавніх модулів (горізонтальний скрол)
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: recentModules.length,
                itemBuilder: (context, index) {
                  final module = recentModules[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: RecentModuleCard(
                      module: module,
                      onTap: () {
                        // Оновлюємо час останнього відкриття
                        module.updateLastOpenedAt();
                        // Тут можна додати навігацію до екрану модуля
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