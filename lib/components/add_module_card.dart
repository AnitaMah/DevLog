import 'package:flutter/material.dart';
import 'package:dev_log/components/module_input_dialog.dart';

class AddModuleCard extends StatelessWidget {
  const AddModuleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const ModuleInputDialog(),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text("Add Module"),
            ],
          ),
        ),
      ),
    );
  }
}