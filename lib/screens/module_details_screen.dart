import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/components/module_tile.dart';
import 'package:dev_log/components/note_tile.dart';
import 'package:dev_log/components/project_status_badge.dart';
import 'package:dev_log/components/project_task_editor.dart';
import 'package:dev_log/helpers/module_actions.dart';
import 'package:dev_log/helpers/folder_import.dart';
import 'package:dev_log/helpers/chat_import.dart';
import 'package:dev_log/helpers/project_status.dart';
import 'package:dev_log/layout/spatial_shell.dart';
import 'package:dev_log/screens/note_editor_screen.dart';

class ModuleDetailsScreen extends StatelessWidget {
  final Module module;

  const ModuleDetailsScreen({super.key, required this.module});

  String get _titleSlug => module.title.toLowerCase().replaceAll(RegExp(r'\s+'), '-');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, Box<Module> moduleBox, _) {
        // Re-reading module.title here (rather than capturing it once)
        // means renaming this module via the edit action below updates the
        // header immediately instead of only after leaving and re-entering.
        final subModules = moduleBox.values.where((m) => m.parentId == module.id).toList();
        final percent = module.taskCompletionPercent;

        // Pushed via Navigator.push as its own full-screen route, so it
        // sits outside DashboardScreen's SpatialShell - wrap here too,
        // same as NoteEditorScreen, otherwise opening a module drops the
        // floating-window chrome/room background the rest of the app has.
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SpatialShell(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          module.isProject ? '~/projects' : '~/modules',
                          style: AppTextStyles.mono.copyWith(color: AppColors.accent),
                        ),
                        Text(' / ', style: AppTextStyles.mono),
                        Expanded(
                          child: Text(
                            _titleSlug,
                            style: AppTextStyles.mono,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _HeaderRow(module: module, percent: percent),
                    if (percent != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      ProjectProgressBar(percent: percent),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: Hive.box<Note>('notes').listenable(),
                        builder: (context, Box<Note> noteBox, _) {
                          final notes = noteBox.values.where((n) => n.moduleId == module.id).toList()
                            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                          if (subModules.isEmpty && notes.isEmpty && !module.isProject) {
                            return Center(
                              child: Text(
                                "Nothing here yet. Use the buttons above to add a note or a submodule.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textDisabled),
                              ),
                            );
                          }

                          return ListView(
                            children: [
                              if (module.isProject) ...[
                                ProjectTaskEditor(module: module),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                              if (notes.isNotEmpty) ...[
                                Text("Notes", style: AppTextStyles.title),
                                const SizedBox(height: AppSpacing.md),
                                ...notes.map((note) => NoteTile(note: note)),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                              if (subModules.isNotEmpty) ...[
                                Text("Submodules", style: AppTextStyles.title),
                                const SizedBox(height: AppSpacing.md),
                                ...subModules.map(
                                  (m) => Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: ModuleTile(module: m),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Title + metadata badges on the left, module actions on the right -
/// matches the mockup's project-detail header row (title, completion/
/// deadline pills, owner line) adapted to this app's plain-module case too.
class _HeaderRow extends StatelessWidget {
  final Module module;
  final int? percent;

  const _HeaderRow({required this.module, required this.percent});

  @override
  Widget build(BuildContext context) {
    final deadline = module.deadline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      module.title,
                      style: AppTextStyles.header.copyWith(fontSize: 32),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (deadline != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ProjectDeadlineBadge(deadline: deadline),
                  ],
                  if (percent != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ProjectPercentBadge(percent: percent!),
                  ],
                ],
              ),
              if (module.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(module.description, style: AppTextStyles.body),
              ] else if (module.isProject) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(projectStatusLabel(module.status), style: AppTextStyles.body),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        AppIconButtonSquare(
          icon: Icons.drive_folder_upload_outlined,
          onPressed: () => _showImportMenu(context, module),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconButtonSquare(
          icon: Icons.create_new_folder_outlined,
          onPressed: () => showDialog(
            context: context,
            builder: (_) => ModuleInputDialog(parentId: module.id, isEditing: false),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconButtonSquare(
          icon: Icons.edit_outlined,
          onPressed: () => showDialog(
            context: context,
            builder: (_) => ModuleInputDialog(module: module, isEditing: true),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconButtonSquare(
          icon: Icons.delete_outline,
          onPressed: () async {
            final deleted = await confirmAndDeleteModule(context, module);
            if (deleted && context.mounted) Navigator.pop(context);
          },
        ),
        const SizedBox(width: AppSpacing.md),
        LiquidSheen(
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: ElevatedButton.icon(
            onPressed: () async {
              await module.updateLastOpenedAt();
              // Pass moduleId (not a pre-created note) so backing out of an
              // empty note doesn't leave an "Untitled note" behind - the
              // editor only creates it on save.
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NoteEditorScreen(moduleId: module.id)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.accentOnColor,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Add note"),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet offering the two ways to bring outside files into
/// [module] directly - skipping the "which module?" step entirely, since
/// we're already looking at the target module.
void _showImportMenu(BuildContext context, Module module) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.sidebarBackground,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.folder_open_outlined, color: AppColors.textSecondary),
            title: Text(
              "Import folder",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              "Add every file in a folder as notes in \"${module.title}\"",
              style: TextStyle(color: AppColors.textDisabled),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              importCodeFolder(context, intoModule: module);
            },
          ),
          ListTile(
            leading: Icon(Icons.note_add_outlined, color: AppColors.textSecondary),
            title: Text(
              "Import files",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              "Pick one or more files to add to \"${module.title}\"",
              style: TextStyle(color: AppColors.textDisabled),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              importFiles(context, intoModule: module);
            },
          ),
          ListTile(
            leading: Icon(Icons.smart_toy_outlined, color: AppColors.textSecondary),
            title: Text(
              "Import AI chat",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              "Add an exported Gemini, Gemini Notebook, or Claude conversation to \"${module.title}\"",
              style: TextStyle(color: AppColors.textDisabled),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              importAiChat(context, intoModule: module);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}
