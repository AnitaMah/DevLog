import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/screens/tagged_notes_screen.dart';

/// Shows the tags used across your notes as colored chips, sized/sorted by
/// how many notes use each one. Tap a chip to see every note with that tag.
class PopularTagsPanel extends StatelessWidget {
  const PopularTagsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Note>>(
      valueListenable: Hive.box<Note>('notes').listenable(),
      builder: (context, _, _) {
        final tags = DatabaseHelper.getAllTagsWithCounts();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Popular Tags", style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.md),
              if (tags.isEmpty)
                Text("No tags yet — add some while editing a note.",
                    style: AppTextStyles.smallText)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((entry) {
                    final color = AppColors.tagColorFor(entry.key);
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaggedNotesScreen(tag: entry.key),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          "${entry.key}  ${entry.value}",
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
