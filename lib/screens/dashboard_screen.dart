import 'package:flutter/material.dart';
import 'package:dev_log/components/module_grid.dart';
import 'package:dev_log/components/recent_modules_section.dart';
import 'package:dev_log/layout/sidebar.dart'; // Імпортуємо ваш компонент Sidebar
import 'package:dev_log/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Встановлюємо загальний фон
      body: Row(
        children: [
          // Постійна бічна панель
          const Sidebar(),
          
          // Основний контент
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