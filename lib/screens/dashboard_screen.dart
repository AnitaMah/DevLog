import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Важливо для listenable()
import 'package:dev_log/components/module_grid.dart';
import 'package:dev_log/components/recent_modules_section.dart';
import 'package:dev_log/layout/sidebar.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/add_module_dialog.dart'; // Для кнопки "Add"

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Додаємо кнопку для створення нових кореневих модулів
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddModuleDialog(parentId: null), // null = корінь
        ),
        label: const Text("New Module"),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.accentPurple,
      ),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome back, Anita 👋", style: AppTextStyles.header),
                  const SizedBox(height: 8),
                  const Text("“Knowledge is organized experience.” — 42", style: AppTextStyles.body),
                  const SizedBox(height: 40),
                  
                  // Секція "Continue where you left off"
                  const RecentModulesSection(),
                  
                  const SizedBox(height: 40),
                  
                  // Секція "Your Modules"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("Your Modules", style: AppTextStyles.title),
                  ),
                  const SizedBox(height: 16),
                  
                  // ModuleGrid тепер автоматично підтягне оновлення через ValueListenableBuilder
                  const ModuleGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
