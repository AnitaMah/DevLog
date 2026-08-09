import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/screens/note_editor_screen.dart';

/// Shows the most recently updated notes across all modules, each tagged
/// with the module it belongs to.
class RecentNotesPanel extends StatelessWidget {
  const RecentNotesPanel({super.key});

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Module>>(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, moduleBox, _) {
        final modulesById = {for (final m in moduleBox.values) m.id: m};

        return ValueListenableBuilder<Box<Note>>(
          valueListenable: Hive.box<Note>('notes').listenable(),
          builder: (context, noteBox, _) {
            final recent = noteBox.values.toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            final topNotes = recent.take(5).toList();

            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Recent Notes", style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.md),
                  if (topNotes.isEmpty)
                    const Text("No notes yet.", style: AppTextStyles.smallText)
                  else
                    ...topNotes.map((note) {
                      final module = modulesById[note.moduleId];
                      final moduleTitle = module?.title ?? "Unknown";

                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: AppTextStyles.body,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.tagColorFor(moduleTitle).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  moduleTitle,
                                  style: TextStyle(
                                    color: AppColors.tagColorFor(moduleTitle),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(_timeAgo(note.updatedAt), style: AppTextStyles.smallText),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
