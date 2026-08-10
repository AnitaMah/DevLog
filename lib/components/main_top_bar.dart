import 'package:flutter/material.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/module_picker_dialog.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/screens/note_editor_screen.dart';

/// Prompts for a module (if needed), creates a new note in it, and opens
/// the note editor. Shared by the "+ New Note" button and the Ctrl+N /
/// Cmd+N keyboard shortcut.
Future<void> createNoteFlow(BuildContext context) async {
  final modules = DatabaseHelper.getAllModules();

  if (modules.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Create a module first, then add notes to it.")),
    );
    return;
  }

  final selected = await showDialog<Module>(
    context: context,
    builder: (_) => ModulePickerDialog(modules: modules),
  );
  if (selected == null) return;

  await selected.updateLastOpenedAt();

  if (context.mounted) {
    // Pass moduleId (not a pre-created note) so the note editor only
    // actually creates a Note record if the user saves it - otherwise
    // backing out of an empty "New Note" used to leave a permanent
    // "Untitled note" behind in the module.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(moduleId: selected.id)),
    );
  }
}

/// Header row for the dashboard: greeting + quote on the left, quick actions
/// (theme toggle, "+ New Note") on the right.
class MainTopBar extends StatelessWidget {
  const MainTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome back, Anita 👋", style: AppTextStyles.header),
              const SizedBox(height: 8),
              Text(
                "“Knowledge is organized experience.” — 42",
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
        _TopIconButton(
          icon: AppColors.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          onPressed: () {
            AppColors.toggle();
            DatabaseHelper.saveThemePreference(AppColors.isDark);
          },
        ),
        const SizedBox(width: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () => createNoteFlow(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("New Note"),
        ),
      ],
    );
  }

}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _TopIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textSecondary, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
