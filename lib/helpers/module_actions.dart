import 'package:flutter/material.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Confirms with the user, then deletes [module] via [DatabaseHelper.deleteModule]
/// - which correctly cascades to submodules *and* their notes.
///
/// Shared by every place a module can be deleted from (grid view, list
/// view, module details screen, ...) so there's exactly one confirmation
/// dialog and one deletion code path to keep in sync, rather than each
/// screen reimplementing (and risking drifting out of sync with) the
/// cascade logic.
///
/// Returns true if the module was actually deleted (user confirmed),
/// false if they cancelled - callers viewing the now-deleted module (e.g.
/// ModuleDetailsScreen showing the module itself) can use this to know
/// whether they need to navigate away.
Future<bool> confirmAndDeleteModule(BuildContext context, Module module) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.sidebarBackground,
      title: Text("Delete module?", style: TextStyle(color: AppColors.textPrimary)),
      content: Text(
        "This permanently deletes \"${module.title}\", along with every "
        "submodule and note inside it. This can't be undone.",
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await DatabaseHelper.deleteModule(module.id);
    return true;
  }
  return false;
}
