import 'package:flutter/material.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/screens/module_screen.dart';
import 'package:dev_log/components/add_module_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Отримуємо всі модулі з бази даних
    final modules = DatabaseHelper.getAllModules();

    return Scaffold(
      appBar: AppBar(
        title: const Text("DevLog"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Modules",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: modules.length + 1, // +1 для кнопки додавання
                itemBuilder: (context, index) {
                  if (index == modules.length) {
                    // Кнопка додавання модуля
                    return const AddModuleCard();
                  }
                  // Картка модуля
                  final module = modules[index];
                  return Card(
                    child: ListTile(
                      title: Text(module.name),
                      subtitle: Text(
                        "${module.submodules.length} submodules | ${module.files.length} files",
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModuleScreen(module: module),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
