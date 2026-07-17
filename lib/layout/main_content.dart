import 'package:flutter/material.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/module_grid.dart';
import 'package:dev_log/components/recent_modules_section.dart'; // Імпортуємо динамічну секцію

class MainContent extends StatelessWidget {
  const MainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome back, Anita 👋", style: AppTextStyles.header),
          const SizedBox(height: 8),
          const Text("“Knowledge is organized experience.” — 42", style: AppTextStyles.body),
          const SizedBox(height: 40),
          
          // Динамічна секція останніх модулів
          const RecentModulesSection(),
          
          const SizedBox(height: 40),
          
          // Секція модулів
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Your Modules", style: AppTextStyles.title),
          ),
          const SizedBox(height: 16),
          const ModuleGrid(), // Використовує новий дизайн Wrap
        ],
      ),
    );
  }
}