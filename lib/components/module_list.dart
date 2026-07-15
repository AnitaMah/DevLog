// lib/components/module_list.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'module_input_dialog.dart'; // Імпорт створеного діалогу

class ModuleList extends StatelessWidget {
  const ModuleList({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, Box<Module> box, _) {
        final modules = box.values.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("MODULES", style: AppTextStyles.cardSubtitle),
            ),
            ...modules.asMap().entries.map((entry) {
              int idx = entry.key;
              Module module = entry.value;
              return ListTile(
                leading: const Icon(Icons.folder_outlined, color: AppColors.textSecondary, size: 18),
                title: Text(module.title, style: AppTextStyles.cardTitle),
                dense: true,
                onLongPress: () => showModuleRenameDialog(context, module, idx),
                onTap: () => print("Open ${module.title}"),
              );
            }),
          ],
        );
      },
    );
  }
}