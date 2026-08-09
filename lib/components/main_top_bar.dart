import 'package:flutter/material.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/module_picker_dialog.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/screens/note_editor_screen.dart';

/// Header row for the dashboard: greeting + quote on the left, quick actions
/// (theme toggle, notifications, "+ New Note") on the right.
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
            children: const [
              Text("Welcome back, Anita 👋", style: AppTextStyles.header),
              SizedBox(height: 8),
              Text(
                "“Knowledge is organized experience.” — 42",
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
        _TopIconButton(icon: Icons.dark_mode_outlined, onPressed: () {}),
        const SizedBox(width: AppSpacing.sm),
        _TopIconButton(icon: Icons.notifications_none, onPressed: () {}),
        const SizedBox(width: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () => _createNote(context),
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

  Future<void> _createNote(BuildContext context) async {
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

    final note = await DatabaseHelper.addNote(selected.id);
    await selected.updateLastOpenedAt();

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
      );
    }
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
