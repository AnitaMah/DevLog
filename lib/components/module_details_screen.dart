import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/components/add_module_dialog.dart'; // Створимо далі

class ModuleDetailsScreen extends StatelessWidget {
  final Module module;

  const ModuleDetailsScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Module>('modules').listenable(),
        builder: (context, Box<Module> box, _) {
          // Фільтруємо модулі, що мають батьківським поточний модуль
          final subModules = box.values.where((m) => m.parentId == module.id).toList();

          return ListView.builder(
            itemCount: subModules.length,
            itemBuilder: (context, index) {
              final sub = subModules[index];
              return ListTile(
                title: Text(sub.title),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ModuleDetailsScreen(module: sub)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddModuleDialog(parentId: module.id),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
