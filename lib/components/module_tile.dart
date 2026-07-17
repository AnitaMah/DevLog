import 'package:flutter/material.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/screens/module_details_screen.dart';

class ModuleTile extends StatelessWidget {
  final Module module;

  const ModuleTile({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.folder),
        title: Text(module.title),
        subtitle: Text(module.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ModuleDetailsScreen(module: module)),
        ),
      ),
    );
  }
}
