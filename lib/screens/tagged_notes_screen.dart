import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/components/note_tile.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Lists every note carrying a given tag. Reached by tapping a chip in
/// [PopularTagsPanel].
class TaggedNotesScreen extends StatefulWidget {
  final String tag;

  const TaggedNotesScreen({super.key, required this.tag});

  @override
  State<TaggedNotesScreen> createState() => _TaggedNotesScreenState();
}

class _TaggedNotesScreenState extends State<TaggedNotesScreen> {
  final TextEditingController _jumpController = TextEditingController();

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  void _jumpToTag(String tag) {
    final target = tag.trim();
    if (target.isEmpty || target == widget.tag) return;
    _jumpController.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaggedNotesScreen(tag: target)),
    );
  }

  /// Existing tags (across every note) starting with whatever's currently
  /// typed into the jump box, excluding the tag already being viewed - so
  /// typing "flu" offers "flutter" instead of letting it drift into a
  /// near-duplicate like "Flutter" or "flutr".
  List<String> _tagSuggestions(String input) {
    final query = input.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return DatabaseHelper.getAllTagsWithCounts()
        .map((entry) => entry.key)
        .where((tag) => tag != query && tag.toLowerCase().startsWith(query) && tag != widget.tag)
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: Text('#${widget.tag}'),
      ),
      body: ValueListenableBuilder<Box<Note>>(
        valueListenable: Hive.box<Note>('notes').listenable(),
        builder: (context, box, _) {
          final notes = DatabaseHelper.getNotesByTag(widget.tag)
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _buildJumpToTag(),
              ),
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Text("No notes tagged '${widget.tag}' anymore.",
                            style: TextStyle(color: AppColors.textDisabled)),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        children: notes.map((note) => NoteTile(note: note)).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJumpToTag() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.tag, size: 16, color: AppColors.textDisabled),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextField(
                  controller: _jumpController,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Jump to tag…",
                    hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 13),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onSubmitted: _jumpToTag,
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _jumpController,
          builder: (context, value, _) {
            final suggestions = _tagSuggestions(value.text);
            if (suggestions.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final suggestion in suggestions)
                    ActionChip(
                      label: Text(suggestion,
                          style: TextStyle(color: AppColors.tagColorFor(suggestion), fontSize: 12)),
                      backgroundColor: AppColors.tagColorFor(suggestion).withValues(alpha: 0.15),
                      side: BorderSide(color: AppColors.tagColorFor(suggestion).withValues(alpha: 0.4)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onPressed: () => _jumpToTag(suggestion),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
