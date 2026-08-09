import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportData() async {
    final json = DatabaseHelper.exportDataAsJson();
    final defaultName =
        '42guides-export-${DateTime.now().toIso8601String().split('T').first}.json';

    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export 42 Guides data',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return; // user cancelled

      await File(path).writeAsString(json);
      _showMessage('Exported to $path');
    } catch (e) {
      _showMessage('Export failed: $e');
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import 42 Guides data',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return; // user cancelled

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.sidebarBackground,
        title: Text("Import data?", style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          "This replaces every module and note currently in the app with "
          "the contents of the selected file. This can't be undone.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Replace data", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final contents = await File(path).readAsString();
      await DatabaseHelper.importDataFromJson(contents);
      _showMessage('Import complete.');
    } catch (e) {
      _showMessage('Import failed: not a valid 42 Guides export file.');
    }
  }

  Future<void> _confirmClearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.sidebarBackground,
        title: Text("Clear all data?", style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          "This permanently deletes every module and note. Your profile and theme "
          "preference are kept. This can't be undone.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete everything", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All modules and notes deleted.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SectionHeader("Appearance"),
          _SettingsTile(
            icon: AppColors.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            title: "Dark mode",
            trailing: Switch(
              value: AppColors.isDark,
              activeColor: AppColors.accentPurple,
              onChanged: (value) {
                setState(() {
                  AppColors.setDark(value);
                  DatabaseHelper.saveThemePreference(value);
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader("Account"),
          _SettingsTile(
            icon: Icons.person_outline,
            title: "Edit profile",
            trailing: Icon(Icons.chevron_right, color: AppColors.textDisabled),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader("Data"),
          _SettingsTile(
            icon: Icons.upload_outlined,
            title: "Export data",
            trailing: Icon(Icons.chevron_right, color: AppColors.textDisabled),
            onTap: _exportData,
          ),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: "Import data",
            trailing: Icon(Icons.chevron_right, color: AppColors.textDisabled),
            onTap: _importData,
          ),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: "Clear all data",
            titleColor: Colors.red,
            onTap: _confirmClearAllData,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader("About"),
          _SettingsTile(icon: Icons.info_outline, title: "42 Guides — version 1.0.0"),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              color: AppColors.textDisabled, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      // Material (not a decorated Container) so the ListTile's ink splash
      // has a Material ancestor to paint on without an opaque box in the way.
      child: Material(
        color: AppColors.cardBackground,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        child: ListTile(
          leading: Icon(icon, color: titleColor ?? AppColors.textSecondary),
          title: Text(title, style: TextStyle(color: titleColor ?? AppColors.textPrimary)),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}
