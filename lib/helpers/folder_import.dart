import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:dev_log/components/module_picker_dialog.dart';
import 'package:dev_log/database/database_helper.dart';
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
/// as a note, and keeps a big folder from freezing the UI.
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
/// brand-new module named after the folder is created to hold them.
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
    final moduleName = await _promptForModuleName(context, folderName);
    if (moduleName == null) return;
    if (!context.mounted) return;

    module = Module(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

  final result = await _runImport(context, entries, module.id);

  // Don't leave an empty module behind if nothing in the folder was
  // actually importable (e.g. it only had binaries/images) - but only
  // if we created it ourselves; never delete a module the user already had.
  if (result.imported == 0 && createdNewModule) {
    await DatabaseHelper.deleteModule(module.id);
  }
  if (context.mounted) {
    _showSummary(context, moduleName: module.title, module: module, result: result);
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

  Module? targetModule = intoModule;

  if (targetModule == null) {
    final modules = DatabaseHelper.getAllModules();
    if (modules.isEmpty) {
      final name = await _promptForModuleName(context, 'Imported files');
      if (name == null) return;
      if (!context.mounted) return;
      targetModule = Module(id: DateTime.now().millisecondsSinceEpoch.toString(), title: name);
      await DatabaseHelper.addModule(targetModule);
    } else {
      targetModule = await showDialog<Module>(
        context: context,
        builder: (_) => ModulePickerDialog(modules: modules),
      );
      if (targetModule == null) return;
    }
  }
  if (!context.mounted) return;

  final entries = [
    for (final f in result.files)
      if (f.path != null) MapEntry(File(f.path!), f.name),
  ];

  final importResult = await _runImport(context, entries, targetModule.id);

  if (context.mounted) {
    _showSummary(context, moduleName: targetModule.title, module: targetModule, result: importResult);
  }
}

class _ImportResult {
  final int imported;
  final int skipped;
  const _ImportResult(this.imported, this.skipped);
}

/// Shows a non-dismissible progress dialog, reads each file in
/// [filesWithTitles] and creates a note for it in the module identified by
/// [moduleId] via [DatabaseHelper.addNote], then closes the dialog.
Future<_ImportResult> _runImport(
  BuildContext context,
  List<MapEntry<File, String>> filesWithTitles,
  String moduleId,
) async {
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

  int imported = 0;
  int skipped = 0;

  try {
    for (final entry in filesWithTitles.take(_maxFiles)) {
      final file = entry.key;
      final title = entry.value;
      try {
        final size = await file.length();
        if (size > _maxFileSizeBytes) {
          skipped++;
          continue;
        }
        final content = await file.readAsString();
        final ext = _extensionOf(title);

        await DatabaseHelper.addNote(
          moduleId,
          title: title,
          content: content,
          tags: ext != null ? [ext] : null,
        );
        imported++;
      } catch (_) {
        // Not valid UTF-8 text (likely a binary file), or unreadable - skip it.
        skipped++;
      }
    }
    if (filesWithTitles.length > _maxFiles) {
      skipped += filesWithTitles.length - _maxFiles;
    }
  } finally {
    if (context.mounted) Navigator.pop(context); // close the progress dialog
  }

  return _ImportResult(imported, skipped);
}

void _showSummary(
  BuildContext context, {
  required String moduleName,
  required Module module,
  required _ImportResult result,
}) {
  final message = result.imported == 0
      ? "No importable text files found."
      : result.skipped > 0
          ? "Imported ${result.imported} file(s) into \"$moduleName\" (${result.skipped} skipped)."
          : "Imported ${result.imported} file(s) into \"$moduleName\".";

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    action: result.imported > 0
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

Future<String?> _promptForModuleName(BuildContext context, String suggestedName) {
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

String? _extensionOf(String relativePath) {
  final name = relativePath.split('/').last;
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == name.length - 1) return null; // no ext, or dotfile, or trailing dot
  return name.substring(dotIndex + 1).toLowerCase();
}
