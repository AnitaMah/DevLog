import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dev_log/components/main_top_bar.dart' show createNoteFlow;
import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/helpers/quick_capture.dart';
import 'package:dev_log/models/activity_item.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/screens/module_details_screen.dart';
import 'package:dev_log/screens/note_editor_screen.dart';
import 'package:dev_log/screens/tagged_notes_screen.dart';
import 'package:dev_log/theme/app_theme.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Home tab content, matching the "Terminal Dark" design reference:
/// terminal-prompt date line, greeting, quick capture, a module grid,
/// recent notes, and popular tags.
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _captureController = TextEditingController();

  @override
  void dispose() {
    _captureController.dispose();
    super.dispose();
  }

  Future<void> _submitCapture(String text) async {
    await captureQuickNote(text);
    _captureController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${_weekdays[now.weekday - 1]} ${now.day} ${_months[now.month - 1]}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 40, 48, 56),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '~/home · $dateLabel',
                        style: AppTextStyles.mono.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text("Welcome back, Anita", style: AppTextStyles.header),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '"Knowledge is organized experience."',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: () => createNoteFlow(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentOnColor,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("New note"),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            GlassPanel(
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: Container(
                height: 60,
                padding: const EdgeInsets.only(left: 20, right: 8),
                child: Row(
                  children: [
                    Text(
                      '>',
                      style: AppTextStyles.mono.copyWith(
                        color: AppColors.accent,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: _captureController,
                        onSubmitted: _submitCapture,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Capture a thought, snippet or TODO…",
                          hintStyle: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '↵ save',
                        style: AppTextStyles.mono.copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const AnchorBadge(label: 'Pinned'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _ModulesSection(),
            const SizedBox(height: AppSpacing.xl),
            ValueListenableBuilder<Box<Module>>(
              valueListenable: Hive.box<Module>('modules').listenable(),
              builder: (context, moduleBox, _) {
                return ValueListenableBuilder<Box<Note>>(
                  valueListenable: Hive.box<Note>('notes').listenable(),
                  builder: (context, noteBox, _) {
                    final modulesById = {
                      for (final m in moduleBox.values) m.id: m,
                    };
                    final notesById = {for (final n in noteBox.values) n.id: n};
                    // Mirrors the mockup's `flex: 2 1 420px` / `flex: 1 1 280px`
                    // row - fills the full available width at a 2:1 ratio,
                    // rather than two fixed-pixel-width boxes.
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _ActivityFeedCard(
                              modulesById: modulesById,
                              notesById: notesById,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _PopularTagsCard()),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModulesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Module>>(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, box, _) {
        final modules = DatabaseHelper.getRootModules();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Your modules", style: AppTextStyles.title)],
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Mirrors the mockup's CSS `repeat(auto-fill, minmax(220px, 1fr))` -
              // columns are at least ~220px, however many fit the width.
              // Aspect ratio matches the mockup's actual card content height
              // (icon + title + meta line, ~125-135px) at that width - the
              // mockup never sets a card height/aspect ratio explicitly, it
              // just sizes to content, which comes out much wider/shorter
              // than square.
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                childAspectRatio: 1.95,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: modules.length + 1,
              itemBuilder: (context, index) {
                if (index == modules.length) return const _AddModuleTile();
                return _ModuleCard(module: modules[index]);
              },
            ),
          ],
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final Module module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.moduleColorFor(module.title);
    return GlassPanel(
      child: InkWell(
        onTap: () {
          module.updateLastOpenedAt();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModuleDetailsScreen(module: module),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: IconHelper.getFaIcon(
                  module.iconName,
                  size: 18,
                  color: fg,
                ),
              ),
              const Spacer(),
              Text(
                module.title,
                style: AppTextStyles.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${DatabaseHelper.getNotesCountForModule(module.id)} notes',
                style: AppTextStyles.mono.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddModuleTile extends StatelessWidget {
  const _AddModuleTile();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => showDialog(
        context: context,
        builder: (_) => const ModuleInputDialog(),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.cardBorder,
            style: BorderStyle.solid,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 22, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Add module",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unified feed of the most recently changed notes and modules, mixed
/// together and ranked by recency (`DatabaseHelper.getRecentActivity`) -
/// replaces the old notes-only "Recent notes" card so project edits (new
/// tasks, status changes, ...) show up here too, not just note edits.
class _ActivityFeedCard extends StatefulWidget {
  final Map<String, Module> modulesById;
  final Map<String, Note> notesById;
  const _ActivityFeedCard({required this.modulesById, required this.notesById});

  @override
  State<_ActivityFeedCard> createState() => _ActivityFeedCardState();
}

class _ActivityFeedCardState extends State<_ActivityFeedCard> {
  String? _moduleFilter;
  String? _tagFilter;
  DateTimeRange? _dateFilter;

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  String _subtitleFor(ActivityItem item) {
    if (item.type == ActivityType.note) {
      final content = widget.notesById[item.id]?.content ?? '';
      return content.isNotEmpty ? content.split('\n').first : 'No content';
    }
    final description = widget.modulesById[item.id]?.description ?? '';
    return description.isNotEmpty ? description : 'Module updated';
  }

  void _open(BuildContext context, ActivityItem item) {
    if (item.type == ActivityType.note) {
      final note = widget.notesById[item.id];
      if (note == null) return; // deleted since the feed last rebuilt
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
      );
    } else {
      final module = widget.modulesById[item.id];
      if (module == null) return;
      module.updateLastOpenedAt();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ModuleDetailsScreen(module: module)),
      );
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateFilter,
    );
    if (picked != null) setState(() => _dateFilter = picked);
  }

  String _dateLabel(DateTimeRange range) {
    String label(DateTime d) => '${_months[d.month - 1]} ${d.day}';
    return '${label(range.start)} – ${label(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final modules = widget.modulesById.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    final tags = DatabaseHelper.getAllTagsWithCounts();
    final activity = DatabaseHelper.getRecentActivity(
      limit: 5,
      moduleId: _moduleFilter,
      tag: _tagFilter,
      after: _dateFilter?.start,
      // DateTimeRange.end is midnight of the end day - extend to its end so
      // that day's own activity is still included.
      before: _dateFilter?.end.add(const Duration(days: 1, microseconds: -1)),
    );
    final hasFilters =
        _moduleFilter != null || _tagFilter != null || _dateFilter != null;

    return GlassPanel(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Text("Activity feed", style: AppTextStyles.sectionTitle),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PopupMenuButton<String?>(
                    color: AppColors.sidebarBackground,
                    onSelected: (value) =>
                        setState(() => _moduleFilter = value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text("All modules"),
                      ),
                      for (final module in modules)
                        PopupMenuItem(
                          value: module.id,
                          child: Text(module.title),
                        ),
                    ],
                    child: _FilterChip(
                      icon: Icons.folder_outlined,
                      label: _moduleFilter == null
                          ? "Module"
                          : (widget.modulesById[_moduleFilter]?.title ??
                                "Module"),
                      active: _moduleFilter != null,
                    ),
                  ),
                  PopupMenuButton<String?>(
                    color: AppColors.sidebarBackground,
                    onSelected: (value) => setState(() => _tagFilter = value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: null, child: Text("All tags")),
                      for (final entry in tags)
                        PopupMenuItem(
                          value: entry.key,
                          child: Text("#${entry.key}"),
                        ),
                    ],
                    child: _FilterChip(
                      icon: Icons.tag,
                      label: _tagFilter == null ? "Tag" : "#$_tagFilter",
                      active: _tagFilter != null,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: () => _pickDateRange(context),
                    child: _FilterChip(
                      icon: Icons.calendar_today_outlined,
                      label: _dateFilter == null
                          ? "Date range"
                          : _dateLabel(_dateFilter!),
                      active: _dateFilter != null,
                    ),
                  ),
                  if (hasFilters)
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () => setState(() {
                        _moduleFilter = null;
                        _tagFilter = null;
                        _dateFilter = null;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (activity.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Text(
                  hasFilters
                      ? "No activity matches these filters."
                      : "No activity yet.",
                  style: AppTextStyles.smallText,
                ),
              )
            else
              ...activity.map((item) {
                final moduleTitle =
                    widget.modulesById[item.moduleId]?.title ?? item.moduleId;
                final (_, dotColor) = AppColors.moduleColorFor(moduleTitle);
                final icon = item.type == ActivityType.module
                    ? Icons.folder_outlined
                    : Icons.description_outlined;
                return InkWell(
                  onTap: () => _open(context, item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.rowDivider),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(icon, size: 14, color: AppColors.textDisabled),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _subtitleFor(item),
                                style: AppTextStyles.cardSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _timeAgo(item.timestamp),
                          style: AppTextStyles.mono.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// A small pill shown inside a [PopupMenuButton]/[InkWell], used for the
/// activity feed's module/tag/date-range quick filters. Purely visual -
/// the tap handling and selected value live in whatever wraps it.
class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.accentMutedBg : AppColors.background,
        border: Border.all(
          color: active ? AppColors.accent : AppColors.cardBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: active ? AppColors.accentMutedFg : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.mono.copyWith(
              fontSize: 12,
              color: active ? AppColors.accentMutedFg : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularTagsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tags = DatabaseHelper.getAllTagsWithCounts();

    return GlassPanel(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Popular tags", style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            if (tags.isEmpty)
              Text(
                "Tags appear here as you add them while editing notes.",
                style: AppTextStyles.smallText,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map(
                      (entry) => InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaggedNotesScreen(tag: entry.key),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border: Border.all(color: AppColors.cardBorder),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '#${entry.key}',
                            style: AppTextStyles.mono.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
