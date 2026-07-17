// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:dev_log/components/module_grid.dart';
import 'package:dev_log/layout/sidebar.dart';
import 'package:dev_log/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("Your Modules", style: AppTextStyles.title),
                  ),
                  const SizedBox(height: 16),
                  const ModuleGrid(), // Показує тільки кореневі модулі
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
