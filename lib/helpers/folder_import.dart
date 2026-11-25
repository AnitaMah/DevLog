import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:dev_log/components/import_preview_dialog.dart';
import 'package:dev_log/components/module_picker_dialog.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/helpers/id_generator.dart';
import 'package:dev_log/helpers/import_conflict_choice.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/screens/module_details_screen.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Directory names that are almost never worth importing as notes - build
/// output, dependency caches, VCS internals, etc.
const _excludedDirNames = {
  '.git', '.svn', '.hg',
  '.dart_tool', '.idea', '.vscode',
  'node_modules', 'venv', '.venv', '__pycache__',
  'build', 'dist', 'target', '.next', '.gradle', 'Pods',
};

/// Skip files bigger than this - almost certainly not something you want
/// as a note, and keeps a big folder from freezing the UI. Callers (e.g.
/// the chat importer) can pass a larger [runImport.maxFileSizeBytes].
const _maxFileSizeBytes = 1024 * 1024; // 1 MB

/// Hard cap on how many files a single import will create notes for, so an
/// accidentally-selected huge folder doesn't hang the app or flood the
/// module with thousands of notes.
const _maxFiles = 300;

/// Picks a folder and imports its files as notes, one per text file
/// (tagged by file extension). Binary files, huge files, and common noise
/// directories (node_modules, .git, build, ...) are skipped automatically.
///
/// If [intoModule] is given, the files are added directly into that
/// existing module (no new module is created or named) - this is the path
/// used when importing from within a module's own screen. Otherwise, a
/// brand-new module named after the folder is created to hold them - unlike
/// [importFiles], this never offers to pick an existing module, since a
/// whole folder's worth of files is naturally its own module.
Future<void> importCodeFolder(BuildContext context, {Module? intoModule}) async {
  final folderPath = await FilePicker.platform.getDirectoryPath(
    dialogTitle: 'Select a code folder to import',
  );
  if (folderPath == null) return; // user cancelled
  if (!context.mounted) return;

  final dir = Directory(folderPath);

  Module module;
  bool createdNewModule = false;

  if (intoModule != null) {
    module = intoModule;
  } else {
    final pathParts = folderPath.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty).toList();
    final folderName = pathParts.isNotEmpty ? pathParts.last : 'Imported folder';

    // Let the user confirm/edit the module name before importing.
    final moduleName = await promptForModuleName(context, folderName);
    if (moduleName == null) return;
    if (!context.mounted) return;

    module = Module(
      id: generateId(),
      title: moduleName,
      iconName: 'folder',
      description: 'Imported from $folderPath',
    );
    await DatabaseHelper.addModule(module);
    createdNewModule = true;
    if (!context.mounted) return;
  }

  final files = _collectFiles(dir);
  final entries = [for (final f in files) MapEntry(f, _relativePath(f.path, dir.path))];

  final conflictChoices = await confirmImportPreview(context, entries, module.id);
  if (conflictChoices == null) {
    if (createdNewModule) await DatabaseHelper.deleteModule(module.id);
    return;
  }
  if (!context.mounted) return;

  final result = await runImport(context, entries, module.id, conflictChoices: conflictChoices);

  // Don't leave an empty module behind if nothing in the folder was
  // actually importable (e.g. it only had binaries/images) - but only
  // if we created it ourselves; never delete a module the user already had.
  if (result.imported == 0 && result.updated == 0 && createdNewModule) {
    await DatabaseHelper.deleteModule(module.id);
  }
  if (context.mounted) {
    showImportSummary(context, moduleName: module.title, module: module, result: result);
  }
}

/// Picks one or more individual files (of any type) and adds each as a
/// note - tagged by extension - to an existing module, or a newly created
/// one if there are no modules yet. Unlike [importCodeFolder], this isn't
/// tied to a single folder's structure, so it's the better fit for adding
/// a handful of unrelated files (e.g. a PDF export, a couple of scripts,
/// some reference docs) to a guide you already have.
///
/// If [intoModule] is given, the module-picker step is skipped entirely and
/// the files are added straight into it - used when importing from within
/// that module's own screen.
Future<void> importFiles(BuildContext context, {Module? intoModule}) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select files to import',
    allowMultiple: true,
    type: FileType.any,
  );
  if (result == null || result.files.isEmpty) return;
  if (!context.mounted) return;

  final resolved = await resolveTargetModule(
    context,
    intoModule: intoModule,
    suggestedModuleName: 'Imported files',
  );
  if (resolved == null) return;
  if (!context.mounted) return;

  final entries = [
    for (final f in result.files)
      if (f.path != null) MapEntry(File(f.path!), f.name),
  ];

  final conflictChoices = await confirmImportPreview(context, entries, resolved.module.id);
  if (conflictChoices == null) {
    if (resolved.createdNew) await DatabaseHelper.deleteModule(resolved.module.id);
    return;
  }
  if (!context.mounted) return;

  final importResult =
      await runImport(context, entries, resolved.module.id, conflictChoices: conflictChoices);

  if (context.mounted) {
    showImportSummary(
        context, moduleName: resolved.module.title, module: resolved.module, result: importResult);
  }
}

/// Resolves which module a batch of imported notes should land in:
/// - if [intoModule] is given, uses it directly (no prompt) - the path
///   used when importing from within a module's own screen.
/// - else if no modules exist yet, prompts for a name (prefilled with
///   [suggestedModuleName]) and creates one.
/// - else shows [ModulePickerDialog] to pick an existing module.
///
/// Returns null if the user cancels at any step. The `createdNew` flag lets
/// a caller clean up (e.g. delete the module) if the import turns out to
/// find nothing importable.
Future<({Module module, bool createdNew})?> resolveTargetModule(
  BuildContext context, {
  Module? intoModule,
  required String suggestedModuleName,
}) async {
  if (intoModule != null) return (module: intoModule, createdNew: false);

  final modules = DatabaseHelper.getAllModules();
  if (modules.isEmpty) {
    final name = await promptForModuleName(context, suggestedModuleName);
    if (name == null) return null;
    if (!context.mounted) return null;
    final module = Module(id: generateId(), title: name);
    await DatabaseHelper.addModule(module);
    return (module: module, createdNew: true);
  }

  final picked = await showDialog<Module>(
    context: context,
    builder: (_) => ModulePickerDialog(modules: modules),
  );
  if (picked == null) return null;
  return (module: picked, createdNew: false);
}

/// Splits [entries] into those that would create a new note and those that
/// would overwrite an existing one in [moduleId] - matched by title, the
/// same match [runImport] itself uses to decide add-vs-update. This is the
/// basis for the import preview shown before anything is actually read or
/// written.
({List<MapEntry<File, String>> newEntries, List<MapEntry<File, String>> conflicting})
    classifyImportEntries(List<MapEntry<File, String>> entries, String moduleId) {
  final existingTitles = {
    for (final note in DatabaseHelper.getNotesForModule(moduleId)) note.title,
  };
  final newEntries = <MapEntry<File, String>>[];
  final conflicting = <MapEntry<File, String>>[];
  for (final entry in entries) {
    (existingTitles.contains(entry.value) ? conflicting : newEntries).add(entry);
  }
  return (newEntries: newEntries, conflicting: conflicting);
}

/// Shows [ImportPreviewDialog] listing which of [entries] are new vs. would
/// overwrite an existing note in [moduleId], letting the user choose - per
/// conflicting file - to overwrite, merge, or skip it, before [runImport]
/// reads or writes anything. Returns the chosen `{title: choice}` map
/// (pass straight to [runImport]'s `conflictChoices`), or null if the user
/// cancels/dismisses the dialog. If [entries] is empty there's nothing to
/// preview, so this returns an empty map immediately - the caller's usual
/// "nothing importable" summary still shows after [runImport] runs.
Future<Map<String, ImportConflictChoice>?> confirmImportPreview(
  BuildContext context,
  List<MapEntry<File, String>> entries,
  String moduleId,
) async {
  if (entries.isEmpty) return {};

  final classified = classifyImportEntries(entries, moduleId);
  if (!context.mounted) return null;

  return showDialog<Map<String, ImportConflictChoice>>(
    context: context,
    builder: (_) => ImportPreviewDialog(
      newEntries: classified.newEntries,
      conflicting: classified.conflicting,
    ),
  );
}

class ImportResult {
  final int imported;
  final int updated;
  final int skipped;
  const ImportResult(this.imported, this.updated, this.skipped);
}

/// Shows a non-dismissible progress dialog, reads each file in
/// [filesWithTitles] and creates or updates a note for it in the module
/// identified by [moduleId], then closes the dialog.
///
/// If a note with the same title already exists in that module (e.g. this
/// folder/file was imported before), [conflictChoices] (keyed by title, as
/// returned by [confirmImportPreview]) decides what happens to it: skip
/// leaves the existing note untouched; merge appends the new content below
/// it (tags are unioned); overwrite (the default when a title isn't in the
/// map - e.g. a caller that skipped the preview) replaces its content in
/// place. Either way nothing is duplicated, so re-importing a folder after
/// pulling new changes refreshes existing notes rather than piling up
/// copies.
///
/// [extractContent] defaults to reading the file as UTF-8 text; pass it to
/// turn other formats (e.g. HTML/PDF chat exports) into plain text instead.
/// [tagsFor] defaults to a single extension-based tag; pass it to tag notes
/// differently (e.g. by AI source instead of file extension). [aiSource],
/// if given, is recorded on every created/updated note. [maxFileSizeBytes]
/// defaults to the 1 MB cap used for plain-text/code imports - chat exports
/// (HTML/PDF) are routinely bigger while still only containing a modest
/// amount of actual text, so callers importing those pass a larger cap.
Future<ImportResult> runImport(
  BuildContext context,
  List<MapEntry<File, String>> filesWithTitles,
  String moduleId, {
  Future<String> Function(File file)? extractContent,
  List<String>? Function(String title)? tagsFor,
  String? aiSource,
  int maxFileSizeBytes = _maxFileSizeBytes,
  Map<String, ImportConflictChoice>? conflictChoices,
}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.sidebarBackground,
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: AppSpacing.lg),
          Text("Importing files…", style: TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    ),
  );
  // Let the progress dialog actually paint before the potentially slow
  // read loop blocks the UI thread.
  await Future<void>.delayed(const Duration(milliseconds: 50));

  // Index existing notes in this module by title so we can detect re-imports
  // and update in place instead of creating duplicates.
  final existingByTitle = {
    for (final note in DatabaseHelper.getNotesForModule(moduleId)) note.title: note,
  };

  int imported = 0;
  int updated = 0;
  int skipped = 0;

  try {
    for (final entry in filesWithTitles.take(_maxFiles)) {
      final file = entry.key;
      final title = entry.value;
      final existing = existingByTitle[title];
      final choice = existing != null
          ? (conflictChoices?[title] ?? ImportConflictChoice.overwrite)
          : null;
      if (choice == ImportConflictChoice.skip) {
        skipped++;
        continue;
      }
      try {
        final size = await file.length();
        if (size > maxFileSizeBytes) {
          skipped++;
          continue;
        }
        final content =
            extractContent != null ? await extractContent(file) : await file.readAsString();
        final ext = extensionOf(title);
        final tags = tagsFor != null ? tagsFor(title) : (ext != null ? [ext] : null);

        if (existing != null) {
          final isMerge = choice == ImportConflictChoice.merge;
          await DatabaseHelper.updateNote(
            existing,
            content: isMerge ? '${existing.content}\n\n---\n\n$content' : content,
            tags: isMerge ? {...existing.tags, ...?tags}.toList() : tags,
            aiSource: aiSource,
          );
          updated++;
        } else {
          final note = await DatabaseHelper.addNote(
            moduleId,
            title: title,
            content: content,
            tags: tags,
            aiSource: aiSource,
          );
          existingByTitle[title] = note; // guard against duplicate titles within this same batch
          imported++;
        }
      } catch (_) {
        // Not valid UTF-8 text (likely a binary file), unreadable, or
        // extraction failed (e.g. a PDF with no text layer) - skip it.
        skipped++;
      }
    }
    if (filesWithTitles.length > _maxFiles) {
      skipped += filesWithTitles.length - _maxFiles;
    }
  } finally {
    if (context.mounted) Navigator.pop(context); // close the progress dialog
  }

  return ImportResult(imported, updated, skipped);
}

void showImportSummary(
  BuildContext context, {
  required String moduleName,
  required Module module,
  required ImportResult result,
}) {
  final parts = <String>[];
  if (result.imported > 0) parts.add("${result.imported} added");
  if (result.updated > 0) parts.add("${result.updated} updated");
  if (result.skipped > 0) parts.add("${result.skipped} skipped");

  final message = parts.isEmpty
      ? "No importable text files found."
      : "${parts.join(', ')} in \"$moduleName\".";

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    action: (result.imported > 0 || result.updated > 0)
        ? SnackBarAction(
            label: 'View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ModuleDetailsScreen(module: module)),
              );
            },
          )
        : null,
  ));
}

Future<String?> promptForModuleName(BuildContext context, String suggestedName) {
  final controller = TextEditingController(text: suggestedName);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.sidebarBackground,
      title: Text("Import as module", style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(labelText: "Module name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final name = controller.text.trim();
            Navigator.pop(context, name.isEmpty ? suggestedName : name);
          },
          child: const Text("Import"),
        ),
      ],
    ),
  );
}

List<File> _collectFiles(Directory dir) {
  final result = <File>[];
  List<FileSystemEntity> entities;
  try {
    entities = dir.listSync(recursive: true, followLinks: false);
  } catch (_) {
    return result;
  }

  for (final entity in entities) {
    if (entity is! File) continue;
    final relative = _relativePath(entity.path, dir.path);
    final segments = relative.split('/');
    if (segments.any(_excludedDirNames.contains)) continue;
    result.add(entity);
  }
  return result;
}

String _relativePath(String fullPath, String basePath) {
  var normalizedFull = fullPath.replaceAll('\\', '/');
  var normalizedBase = basePath.replaceAll('\\', '/');
  if (!normalizedBase.endsWith('/')) normalizedBase += '/';
  if (normalizedFull.startsWith(normalizedBase)) {
    normalizedFull = normalizedFull.substring(normalizedBase.length);
  }
  return normalizedFull;
}

String? extensionOf(String relativePath) {
  final name = relativePath.split('/').last;
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == name.length - 1) return null; // no ext, or dotfile, or trailing dot
  return name.substring(dotIndex + 1).toLowerCase();
}
