import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dev_log/theme/app_theme.dart'; // Використовуйте повний шлях вашого проекту [3, 4]
import 'package:dev_log/models/module.dart';

class AddModuleCard extends StatelessWidget {
  const AddModuleCard({super.key});

  // Функція для додавання нового модуля
  void _addNewModule(BuildContext context) {
    final box = Hive.box<Module>('modules');
    
    // Створюємо унікальний ID на основі поточного часу [5]
    final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

    final newModule = Module(
      id: uniqueId, // Обов'язкове поле згідно з новою моделлю
      title: "New Module ${box.length + 1}", 
      description: "Enter description for this module...", // Обов'язкове поле
      notesCount: 0,
      // createdAt заповниться автоматично в моделі, якщо не передано [sources]
    );
    
    box.add(newModule); // Запис у Hive
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _addNewModule(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // Використовуємо кольори з вашої централізованої теми [6-8]
            color: AppColors.textSecondary.withOpacity(0.3), 
            style: BorderStyle.solid, 
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              // Використовуємо AppTextStyles для уникнення помилки "AppStyles isn't defined" [9-11]
              Text("Add Module", style: AppTextStyles.cardSubtitle),
            ],
          ),
        ),
      ),
    );
  }
}