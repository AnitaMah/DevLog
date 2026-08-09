import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/note.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/components/module_tile.dart';
import 'package:dev_log/components/note_tile.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/screens/note_editor_screen.dart';

class ModuleDetailsScreen extends StatelessWidget {
  final Module module;

  const ModuleDetailsScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(module.title, style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.cardBackground,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "add_submodule",
            backgroundColor: AppColors.cardBackground,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ModuleInputDialog(parentId: module.id, isEditing: false),
            ),
            child: Icon(Icons.create_new_folder_outlined, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          FloatingActionButton.extended(
            heroTag: "add_note",
            backgroundColor: AppColors.accentPurple,
            onPressed: () async {
              final note = await DatabaseHelper.addNote(module.id);
              await module.updateLastOpenedAt();
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
                );
              }
            },
            label: const Text("Add Note"),
            icon: const Icon(Icons.note_add_outlined),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Module>('modules').listenable(),
        builder: (context, Box<Module> moduleBox, _) {
          final subModules = moduleBox.values.where((m) => m.parentId == module.id).toList();

          return ValueListenableBuilder(
            valueListenable: Hive.box<Note>('notes').listenable(),
            builder: (context, Box<Note> noteBox, _) {
              final notes = noteBox.values.where((n) => n.moduleId == module.id).toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

              if (subModules.isEmpty && notes.isEmpty) {
                return Center(
                  child: Text(
                    "Nothing here yet. Use the buttons below to add a note or a submodule.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDisabled),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (notes.isNotEmpty) ...[
                    Text("Notes", style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.md),
                    ...notes.map((note) => NoteTile(note: note)),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  if (subModules.isNotEmpty) ...[
                    Text("Submodules", style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.md),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: subModules.length,
                      itemBuilder: (context, index) => ModuleTile(module: subModules[index]),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
