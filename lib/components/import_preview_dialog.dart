import 'dart:io';

import 'package:flutter/material.dart';

import 'package:dev_log/helpers/import_conflict_choice.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Shown after files are picked but before anything is read or written, so
/// the user can see which files are brand new and which already exist in
/// the target module, and choose - per conflicting file - whether to
/// overwrite, merge, or skip it. Pops a `{title: choice}` map for the
/// conflicting entries to proceed (new entries aren't in it - they're
/// always added), or null if cancelled/dismissed.
class ImportPreviewDialog extends StatefulWidget {
  final List<MapEntry<File, String>> newEntries;
  final List<MapEntry<File, String>> conflicting;

  const ImportPreviewDialog({super.key, required this.newEntries, required this.conflicting});

  @override
  State<ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<ImportPreviewDialog> {
  late Map<String, ImportConflictChoice> _choices;

  @override
  void initState() {
    super.initState();
    _choices = {
      for (final entry in widget.conflicting) entry.value: ImportConflictChoice.overwrite,
    };
  }

  @override
  Widget build(BuildContext context) {
    final skippedCount =
        _choices.values.where((c) => c == ImportConflictChoice.skip).length;
    final willImport = widget.newEntries.length + widget.conflicting.length - skippedCount;

    return AlertDialog(
      backgroundColor: AppColors.sidebarBackground,
      title: Text("Review import", style: TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.newEntries.isNotEmpty)
                _NewSection(title: "New (${widget.newEntries.length})", entries: widget.newEntries),
              if (widget.conflicting.isNotEmpty) ...[
                if (widget.newEntries.isNotEmpty) const SizedBox(height: AppSpacing.lg),
                _ConflictSection(
                  title: "Already in this module (${widget.conflicting.length})",
                  entries: widget.conflicting,
                  choices: _choices,
                  onChoiceChanged: (title, choice) => setState(() => _choices[title] = choice),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _choices),
          child: Text(willImport > 0 ? "Import $willImport" : "Import"),
        ),
      ],
    );
  }
}

class _NewSection extends StatelessWidget {
  final String title;
  final List<MapEntry<File, String>> entries;

  const _NewSection({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTextStyles.cardTitle.copyWith(color: AppColors.accent)),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 160),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: entries.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                entries[index].value,
                style: AppTextStyles.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConflictSection extends StatelessWidget {
  final String title;
  final List<MapEntry<File, String>> entries;
  final Map<String, ImportConflictChoice> choices;
  final void Function(String title, ImportConflictChoice choice) onChoiceChanged;

  const _ConflictSection({
    required this.title,
    required this.entries,
    required this.choices,
    required this.onChoiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTextStyles.cardTitle.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Same name as an existing note - choose what to do with each one.",
          style: AppTextStyles.smallText,
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final fileTitle = entries[index].value;
              final choice = choices[fileTitle] ?? ImportConflictChoice.overwrite;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fileTitle,
                        style: AppTextStyles.body,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    DropdownButton<ImportConflictChoice>(
                      value: choice,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.sidebarBackground,
                      style: AppTextStyles.body,
                      items: [
                        for (final option in ImportConflictChoice.values)
                          DropdownMenuItem(value: option, child: Text(option.label)),
                      ],
                      onChanged: (value) {
                        if (value != null) onChoiceChanged(fileTitle, value);
                      },
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
}
