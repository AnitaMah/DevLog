import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/screens/module_details_screen.dart';
import 'package:dev_log/screens/note_editor_screen.dart';

/// Shown in the sidebar in place of the module tree while there's an
/// active search query. Matches modules by title and notes by title or
/// content, and lets you jump straight to either.
class SearchResultsList extends StatelessWidget {
  final String query;

  const SearchResultsList({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    return ValueListenableBuilder<Box<Module>>(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, moduleBox, _) {
        return ValueListenableBuilder<Box<Note>>(
          valueListenable: Hive.box<Note>('notes').listenable(),
          builder: (context, noteBox, _) {
            final matchingModules =
                moduleBox.values.where((m) => m.title.toLowerCase().contains(q)).toList();
            final matchingNotes = noteBox.values
                .where((n) =>
                    n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q))
                .toList();

            if (matchingModules.isEmpty && matchingNotes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "No matches.",
                  style: AppTextStyles.smallText,
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (matchingModules.isNotEmpty) ...[
                    _SectionLabel("Modules"),
                    ...matchingModules.map((module) => ListTile(
                          dense: true,
                          leading: IconHelper.getFaIcon(module.iconName,
                              size: 16, color: AppColors.accentPurple),
                          title: Text(module.title, style: AppTextStyles.cardTitle),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ModuleDetailsScreen(module: module),
                            ),
                          ),
                        )),
                  ],
                  if (matchingNotes.isNotEmpty) ...[
                    _SectionLabel("Notes"),
                    ...matchingNotes.map((note) => ListTile(
                          dense: true,
                          leading: Icon(Icons.description_outlined,
                              size: 16, color: AppColors.textSecondary),
                          title: Text(note.title, style: AppTextStyles.cardTitle),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
                          ),
                        )),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              color: AppColors.textDisabled, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
