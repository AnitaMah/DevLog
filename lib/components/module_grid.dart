import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/theme/app_theme.dart'; 
import 'package:dev_log/models/module.dart';
import 'package:dev_log/components/add_module_card.dart'; // Виправлено шлях [10]

class ModuleGrid extends StatelessWidget {
  const ModuleGrid({super.key});

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
            crossAxisCount: 3, // Відповідає макету [11]
            childAspectRatio: 2.2, 
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: modules.length + 1, 
          itemBuilder: (context, index) {
            if (index == modules.length) {
              // ВИДАЛЕНО const: AddModuleCard працює з Hive [3, 6]
              return AddModuleCard(); 
            }

            final module = modules[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground, // Виправлено: cardBackground замість card [12, 13]
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Виправлено: AppTextStyles замість AppStyles [14-16]
                  Text(
                    module.title, 
                    style: AppTextStyles.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${module.notesCount} notes", 
                    style: AppTextStyles.cardSubtitle,
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