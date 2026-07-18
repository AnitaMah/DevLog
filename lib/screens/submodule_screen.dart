import 'package:flutter/material.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/submodule.dart';
import 'package:dev_log/database/database_helper.dart';

class SubmoduleScreen extends StatelessWidget {
  final Module module;
  final Submodule submodule;

  const SubmoduleScreen({
    super.key,
    required this.module,
    required this.submodule,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(submodule.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Files in Submodule",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: submodule.files.length,
                itemBuilder: (context, index) {
                  final file = submodule.files[index];
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFileDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddFileDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add File to Submodule"),
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
                DatabaseHelper.addFileToSubmodule(
                  module.id,
                  submodule.id,
                  fileName,
                );
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
