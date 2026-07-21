import 'package:flutter/material.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/submodule.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/screens/submodule_screen.dart';

class ModuleScreen extends StatelessWidget {
  final Module module;

  const ModuleScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(module.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFileDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Submodules",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: module.submodules.length,
                itemBuilder: (context, index) {
                  final submodule = module.submodules[index];
                  return Card(
                    child: ListTile(
                      title: Text(submodule.name),
                      subtitle: Text("${submodule.files.length} files"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubmoduleScreen(
                            module: module,
                            submodule: submodule,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Files",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: module.files.length,
                itemBuilder: (context, index) {
                  final file = module.files[index];
                  return ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(file),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _showAddSubmoduleDialog(context),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _showAddFileDialog(context),
            child: const Icon(Icons.note_add),
          ),
        ],
      ),
    );
  }

  void _showAddSubmoduleDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Submodule"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Submodule Name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final submoduleName = nameController.text.trim();
              if (submoduleName.isNotEmpty) {
                final newSubmodule = Submodule(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: submoduleName,
                );
                DatabaseHelper.addSubmodule(module.id, newSubmodule);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showAddFileDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add File to Module"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "File Name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final fileName = nameController.text.trim();
              if (fileName.isNotEmpty) {
                DatabaseHelper.addFileToModule(module.id, fileName);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
