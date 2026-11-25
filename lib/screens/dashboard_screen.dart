import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dev_log/components/main_top_bar.dart' show createNoteFlow;
import 'package:dev_log/layout/home_content.dart';
import 'package:dev_log/layout/sidebar.dart';
import 'package:dev_log/screens/notes_screen.dart';
import 'package:dev_log/screens/projects_screen.dart';
import 'package:dev_log/screens/settings_screen.dart';
import 'package:dev_log/screens/tags_screen.dart';
import 'package:dev_log/theme/app_theme.dart';

/// The app's shell: a persistent [Sidebar] next to a tab-switched body
/// (Home / Projects / Notes / Tags / Settings), matching the "Terminal
/// Dark" design reference's sidebar layout.
///
/// Also owns the app-wide keyboard shortcuts: Ctrl/Cmd+N starts a new note,
/// Ctrl/Cmd+F switches to the Notes tab and focuses its search field.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final FocusNode _notesSearchFocusNode = FocusNode();

  @override
  void dispose() {
    _notesSearchFocusNode.dispose();
    super.dispose();
  }

  void _focusNotesSearch() {
    setState(() => _currentIndex = 2);
    // Wait a frame so the Notes tab (and its search field) actually exists
    // before trying to focus it - same reasoning as
    // NoteEditorScreen._popWhenClean's post-frame callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notesSearchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            () => createNoteFlow(context),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
            () => createNoteFlow(context),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): _focusNotesSearch,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF): _focusNotesSearch,
      },
      // CallbackShortcuts only fires when some descendant already holds
      // keyboard focus - without this, the bindings above are silently
      // inert until the user happens to click something focusable first.
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Row(
              children: [
                Sidebar(
                  currentIndex: _currentIndex,
                  onIndexSelected: (index) => setState(() => _currentIndex = index),
                  onSearchTap: _focusNotesSearch,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      const HomeContent(),
                      const ProjectsScreen(),
                      NotesScreen(searchFocusNode: _notesSearchFocusNode),
                      const TagsScreen(),
                      const SettingsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
