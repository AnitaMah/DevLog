import 'package:flutter/material.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/module_input_dialog.dart';

class AddModuleCard extends StatelessWidget {
  const AddModuleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const ModuleInputDialog(),
        );
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.accentPurple, // Фіолетовий колір
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.accentPurple,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                "Add Module",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
