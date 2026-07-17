import 'package:flutter/material.dart';
import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/theme/app_theme.dart';

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
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.textDisabled, 
            style: BorderStyle.solid, // Використовуємо solid замість dashed для сумісності
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.textDisabled, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                "Add Module", 
                style: TextStyle(
                  color: AppColors.textDisabled, 
                  fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}