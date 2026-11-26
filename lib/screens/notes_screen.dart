import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dev_log/helpers/search_index.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/search_bar_widget.dart';
import 'package:dev_log/screens/note_editor_screen.dart';

/// Notes tab: search across every note, or browse all of them (most
/// recently updated first) when there's no query.
class NotesScreen extends StatefulWidget {
  final FocusNode searchFocusNode;

  const NotesScreen({super.key, required this.searchFocusNode});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';
  String? _selectedModuleId;
  late final ValueListenable<Box<Note>> _noteListenable;
  SearchIndex _index = SearchIndex.build(const []);

  @override
  void initState() {
    super.initState();
    _noteListenable = Hive.box<Note>('notes').listenable();
    _rebuildIndex();
    _noteListenable.addListener(_rebuildIndex);
  }

  @override
  void dispose() {
    _noteListenable.removeListener(_rebuildIndex);
    super.dispose();
  }

  // Rebuilt only when the notes box actually changes, not on every
  // keystroke - typing just re-queries the already-built index.
  void _rebuildIndex() {
    setState(() => _index = SearchIndex.build(_noteListenable.value.values.toList()));
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        Text('~/notes', style: AppTextStyles.mono.copyWith(color: AppColors.accent)),
      ],
    );
  }

  Widget _buildModuleFilterRow(List<Module> modules) {
    Widget chip(String label, {required bool selected, required VoidCallback onTap}) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          backgroundColor: AppColors.cardBackground,
          selectedColor: AppColors.accentMutedBg,
          labelStyle: TextStyle(
            color: selected ? AppColors.accentMutedFg : AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: selected ? AppColors.accent.withValues(alpha: 0.4) : AppColors.cardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All modules', selected: _selectedModuleId == null, onTap: () => setState(() => _selectedModuleId = null)),
          for (final module in modules)
            chip(module.title,
                selected: _selectedModuleId == module.id,
                onTap: () => setState(() => _selectedModuleId = module.id)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _index.search(_query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBreadcrumb(),
        const SizedBox(height: AppSpacing.sm),
        SearchBarWidget(
          focusNode: widget.searchFocusNode,
          onChanged: (value) => setState(() => _query = value),
        ),
        Expanded(
          child: ValueListenableBuilder<Box<Module>>(
            valueListenable: Hive.box<Module>('modules').listenable(),
            builder: (context, moduleBox, _) {
              final modulesById = {for (final m in moduleBox.values) m.id: m};
              final visibleNotes =
                  _selectedModuleId == null ? notes : notes.where((n) => n.moduleId == _selectedModuleId).toList();

              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${visibleNotes.length} notes in ${moduleBox.values.length} modules',
                      style: AppTextStyles.cardSubtitle.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildModuleFilterRow(moduleBox.values.toList()),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: visibleNotes.isEmpty
                          ? Center(
                              child: Text(
                                _query.trim().isEmpty ? "No notes yet." : "No matches.",
                                style: TextStyle(color: AppColors.textDisabled),
                              ),
                            )
                          : _buildGlassList(visibleNotes, modulesById),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGlassList(List<Note> notes, Map<String, Module> modulesById) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppGlass.blurSigma, sigmaY: AppGlass.blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: AppGlass.panelBackground,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppGlass.panelBorder),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            itemCount: notes.length,
            separatorBuilder: (_, _) => Divider(color: AppColors.divider, height: AppSpacing.lg),
            itemBuilder: (context, index) {
              final note = notes[index];
              final moduleTitle = modulesById[note.moduleId]?.title ?? "Unknown";
              final dotColor = AppColors.tagColorFor(moduleTitle);

              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
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
                          color: dotColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          moduleTitle,
                          style: TextStyle(color: dotColor, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(_timeAgo(note.updatedAt), style: AppTextStyles.smallText),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
