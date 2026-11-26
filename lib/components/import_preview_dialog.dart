import 'dart:io';
import 'dart:ui' show ImageFilter;

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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppGlass.blurSigma, sigmaY: AppGlass.blurSigma),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppGlass.panelBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppGlass.panelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCrumb(),
                const SizedBox(height: AppSpacing.lg),
                Flexible(
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
                const SizedBox(height: AppSpacing.lg),
                Divider(color: AppColors.divider),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent, foregroundColor: AppColors.accentOnColor),
                      onPressed: () => Navigator.pop(context, _choices),
                      child: Text(willImport > 0 ? "Import $willImport" : "Import"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCrumb() {
    return Row(
      children: [
        Text('~/import', style: AppTextStyles.mono.copyWith(color: AppColors.accent)),
        const SizedBox(width: AppSpacing.sm),
        Text('/', style: AppTextStyles.mono),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text('Review import', style: AppTextStyles.cardTitle)),
      ],
    );
  }
}

/// Pill-shaped status badge (e.g. "new" / "conflict") matching the status
/// chips on the Terminal Dark / Spatial import screen - a colored,
/// fully-rounded fill rather than the plain inline text this dialog used
/// before.
class _StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusPill({required this.label, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        label,
        style: AppTextStyles.mono.copyWith(color: foreground, fontSize: 11, fontWeight: FontWeight.w700),
      ),
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entries[index].value,
                      style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const _StatusPill(
                    label: 'new',
                    background: AppColors.accentMutedBg,
                    foreground: AppColors.accentMutedFg,
                  ),
                ],
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
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fileTitle,
                        style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const _StatusPill(
                      label: 'conflict',
                      background: AppColors.dangerBg,
                      foreground: AppColors.danger,
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
