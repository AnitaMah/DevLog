import 'package:flutter/material.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/screens/note_editor_screen.dart';

/// A single row representing a [Note] inside a module's note list.
class NoteTile extends StatelessWidget {
  final Note note;

  const NoteTile({super.key, required this.note});

  String _preview(String content) {
    final singleLine = content.replaceAll('\n', ' ').trim();
    return singleLine.isEmpty ? "No content yet" : singleLine;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        leading: const Icon(Icons.description_outlined, color: AppColors.accentPurple, size: 20),
        title: Text(note.title, style: AppTextStyles.cardTitle),
        subtitle: Text(
          _preview(note.content),
          style: AppTextStyles.cardSubtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
        ),
      ),
    );
  }
}
