import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../theme/app_theme.dart';
import '../models/module.dart';

class AddModuleCard extends StatelessWidget {
  const AddModuleCard({super.key});

  // Функція для додавання нового модуля
  void _addNewModule(BuildContext context) {
    final box = Hive.box<Module>('modules');
    
    // Для тесту додаємо модуль зі стандартною назвою
    // У майбутньому тут можна викликати showDialog з текстовим полем
    final newModule = Module(
      title: "New Module ${box.length + 1}", 
      notesCount: 0
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
            color: AppColors.textSecondary.withOpacity(0.3), 
            style: BorderStyle.solid, // Можна налаштувати на пунктир (dashed)
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text("Add Module", style: AppTextStyles.cardSubtitle),
            ],
          ),
        ),
      ),
    );
  }
}