import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dev_log/layout/sidebar.dart';
import 'package:dev_log/layout/main_content.dart';
import 'package:dev_log/components/main_top_bar.dart' show createNoteFlow;
import 'package:dev_log/theme/app_theme.dart';

/// The app's home screen: a persistent [Sidebar] with module navigation
/// next to the scrollable [MainContent] dashboard.
///
/// Also owns the app-wide keyboard shortcuts: Ctrl/Cmd+N starts a new note,
/// Ctrl/Cmd+F focuses the sidebar search field.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            () => createNoteFlow(context),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
            () => createNoteFlow(context),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            () => _searchFocusNode.requestFocus(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF):
            () => _searchFocusNode.requestFocus(),
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Row(
            children: [
              Sidebar(searchFocusNode: _searchFocusNode),
              const Expanded(child: MainContent()),
            ],
          ),
        ),
      ),
    );
  }
}
