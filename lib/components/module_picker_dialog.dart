import 'package:flutter/material.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/helpers/icon_helper.dart';

/// Lets the user pick which module a new note should belong to.
/// Pops with the selected [Module], or null if cancelled.
class ModulePickerDialog extends StatelessWidget {
  final List<Module> modules;

  const ModulePickerDialog({super.key, required this.modules});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.sidebarBackground,
      title: const Text("Add note to…", style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 320,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            final isSubmodule = module.parentId != null;
            return ListTile(
              contentPadding: EdgeInsets.only(left: isSubmodule ? 32 : 16, right: 16),
              leading: IconHelper.getFaIcon(module.iconName, size: 16, color: AppColors.accentPurple),
              title: Text(module.title, style: AppTextStyles.cardTitle),
              onTap: () => Navigator.pop(context, module),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
