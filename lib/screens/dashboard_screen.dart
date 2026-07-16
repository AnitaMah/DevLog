import 'package:flutter/material.dart';
import 'package:dev_log/components/module_grid.dart';
import 'package:dev_log/components/recent_modules_section.dart';
import 'package:dev_log/components/menu_navigation.dart'; // Додано для бічної панелі

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome back, Anita 👋"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      // Додано Drawer для бічної панелі
      drawer: const MenuNavigation(),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Секція "Continue where you left off" (динамічна)
            const RecentModulesSection(),

            // Секція "Your Modules"
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Your Modules",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const ModuleGrid(),
          ],
        ),
      ),
    );
  }
}