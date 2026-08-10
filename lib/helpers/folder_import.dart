import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
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

/// Picks a folder, then creates a new module named after it with one note
/// per text file inside (tagged by file extension). Binary files, huge
/// files, and common noise directories (node_modules, .git, build, ...)
/// are skipped automatically.
Future<void> importCodeFolder(BuildContext context) async {
  final folderPath = await FilePicker.platform.getDirectoryPath(
    dialogTitle: 'Select a code folder to import',
  );
  if (folderPath == null) return; // user cancelled
  if (!context.mounted) return;

  final dir = Directory(folderPath);
  final pathParts = folderPath.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty).toList();
  final folderName = pathParts.isNotEmpty ? pathParts.last : 'Imported folder';

  // Let the user confirm/edit the module name before importing.
  final moduleName = await _promptForModuleName(context, folderName);
  if (moduleName == null) return;
  if (!context.mounted) return;

  // Non-dismissible progress indicator - importing a few hundred files can
  // take a moment.
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

  // Let the progress dialog actually paint before the (synchronous, and
  // potentially slow for a big folder) directory scan blocks the UI thread.
  await Future<void>.delayed(const Duration(milliseconds: 50));

  int imported = 0;
  int skipped = 0;

  try {
    final module = Module(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: moduleName,
      iconName: 'folder',
      description: 'Imported from $folderPath',
    );
    await DatabaseHelper.addModule(module);

    final files = _collectFiles(dir);
    for (final file in files.take(_maxFiles)) {
      final relativePath = _relativePath(file.path, dir.path);

      try {
        final size = await file.length();
        if (size > _maxFileSizeBytes) {
          skipped++;
          continue;
        }
        final content = await file.readAsString();
        final ext = _extensionOf(relativePath);

        await DatabaseHelper.addNote(
          module.id,
          title: relativePath,
          content: content,
          tags: ext != null ? [ext] : null,
        );
        imported++;
      } catch (_) {
        // Not valid UTF-8 text (likely a binary file), or unreadable - skip it.
        skipped++;
      }
    }
    if (files.length > _maxFiles) {
      skipped += files.length - _maxFiles;
    }
  } finally {
    if (context.mounted) Navigator.pop(context); // close the progress dialog
  }

  if (context.mounted) {
    final message = skipped > 0
        ? "Imported $imported file(s) into \"$moduleName\" ($skipped skipped)."
        : "Imported $imported file(s) into \"$moduleName\".";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
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
