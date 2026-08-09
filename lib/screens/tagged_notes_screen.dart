import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/components/note_tile.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Lists every note carrying a given tag. Reached by tapping a chip in
/// [PopularTagsPanel].
class TaggedNotesScreen extends StatelessWidget {
  final String tag;

  const TaggedNotesScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: Text('#$tag'),
      ),
      body: ValueListenableBuilder<Box<Note>>(
        valueListenable: Hive.box<Note>('notes').listenable(),
        builder: (context, box, _) {
          final notes = DatabaseHelper.getNotesByTag(tag)
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          if (notes.isEmpty) {
            return Center(
              child: Text("No notes tagged '$tag' anymore.",
                  style: TextStyle(color: AppColors.textDisabled)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: notes.map((note) => NoteTile(note: note)).toList(),
          );
        },
      ),
    );
  }
}
