import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/screens/tagged_notes_screen.dart';

/// Tags tab: every tag used across your notes, as colored chips sized/
/// sorted by how many notes use each one. Tap a chip to see those notes.
class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Note>>(
      valueListenable: Hive.box<Note>('notes').listenable(),
      builder: (context, _, _) {
        final tags = DatabaseHelper.getAllTagsWithCounts();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(48, 40, 48, 56),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tags", style: AppTextStyles.header.copyWith(fontSize: 32)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Every tag used across your notes — tap one to see those notes.",
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xl),
                GlassPanel(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    width: double.infinity,
                    child: tags.isEmpty
                        ? Text(
                            "No tags yet — add some while editing a note.",
                            style: AppTextStyles.smallText,
                          )
                        : Wrap(
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
