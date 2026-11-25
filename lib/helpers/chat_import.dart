import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/helpers/chat_text_extraction.dart';
import 'package:dev_log/helpers/folder_import.dart';
import 'package:dev_log/models/ai_source.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/theme/app_theme.dart';

/// Chat exports (HTML/PDF) run bigger than plain code files while still
/// only containing a modest amount of actual text, so this is looser than
/// the 1 MB cap used for code/text imports.
const _maxChatFileSizeBytes = 20 * 1024 * 1024; // 20 MB

/// Picks one or more exported Gemini / Gemini Notebook / Claude chat files
/// (.html/.htm/.pdf), extracts their readable text, and adds each as a note
/// - tagged with the AI's name and recording it as structured [Note.aiSource]
/// metadata - into an existing module, or a newly created one.
///
/// If [intoModule] is given, the module-picker step is skipped entirely and
/// the files are added straight into it - used when importing from within
/// that module's own screen. Mirrors [importFiles]'s shape, reusing the
/// same [resolveTargetModule]/[runImport]/[showImportSummary] pipeline.
Future<void> importAiChat(BuildContext context, {Module? intoModule}) async {
  final source = await _promptForAiSource(context);
  if (source == null) return; // user cancelled
  if (!context.mounted) return;

  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select exported ${source.label} chat file(s)',
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: ['html', 'htm', 'pdf'],
  );
  if (result == null || result.files.isEmpty) return;
  if (!context.mounted) return;

  final resolved = await resolveTargetModule(
    context,
    intoModule: intoModule,
    suggestedModuleName: '${source.label} chats',
  );
  if (resolved == null) return;
  if (!context.mounted) return;

  final entries = [
    for (final f in result.files)
      if (f.path != null) MapEntry(File(f.path!), _titleFromFileName(f.name)),
  ];

  final conflictChoices = await confirmImportPreview(context, entries, resolved.module.id);
  if (conflictChoices == null) {
    if (resolved.createdNew) await DatabaseHelper.deleteModule(resolved.module.id);
    return;
  }
  if (!context.mounted) return;

  final importResult = await runImport(
    context,
    entries,
    resolved.module.id,
    extractContent: _extractChatContent,
    tagsFor: (_) => [source.tagLabel],
    aiSource: source.storageValue,
    maxFileSizeBytes: _maxChatFileSizeBytes,
    conflictChoices: conflictChoices,
  );

  if (importResult.imported == 0 && importResult.updated == 0 && resolved.createdNew) {
    await DatabaseHelper.deleteModule(resolved.module.id);
  }
  if (context.mounted) {
    showImportSummary(
        context, moduleName: resolved.module.title, module: resolved.module, result: importResult);
  }
}

/// One dialog, shown once per import batch, before the file picker - not
/// per-file auto-detection. Export markup differs and is unreliable per
/// provider, so a single explicit choice for the whole batch is both
/// simpler and more trustworthy than trying to sniff it from the HTML/PDF.
Future<AiSource?> _promptForAiSource(BuildContext context) {
  return showDialog<AiSource>(
    context: context,
    builder: (context) => SimpleDialog(
      backgroundColor: AppColors.sidebarBackground,
      title: Text("Which AI is this chat from?", style: TextStyle(color: AppColors.textPrimary)),
      children: [
        for (final source in AiSource.values)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, source),
            child: Text(source.label, style: TextStyle(color: AppColors.textPrimary)),
          ),
      ],
    ),
  );
}

Future<String> _extractChatContent(File file) async {
  final ext = extensionOf(file.path);
  if (ext == 'pdf') {
    return extractTextFromPdf(await file.readAsBytes());
  }
  return extractTextFromHtml(await file.readAsString());
}

/// Strips the extension so a note isn't titled "conversation.html".
String _titleFromFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot > 0 ? fileName.substring(0, dot) : fileName;
}
