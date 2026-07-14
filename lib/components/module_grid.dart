import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../models/module.dart';
import 'add_module_card.dart';

class ModuleGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, Box<Module> box, _) {
        final modules = box.values.toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Як у вашому макеті [1]
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          // Додаємо +1 до довжини списку для кнопки "Add Module"
          itemCount: modules.length + 1, 
          itemBuilder: (context, index) {
            // Якщо це останній елемент — показуємо кнопку додавання
            if (index == modules.length) {
              return const AddModuleCard();
            }

            final module = modules[index];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground, // З вашої теми [6, 7]
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(module.title, style: AppTextStyles.cardTitle),
                    Text("${module.notesCount} notes", style: AppTextStyles.cardSubtitle),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}