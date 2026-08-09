import 'package:flutter/material.dart';
import 'package:dev_log/layout/sidebar.dart';
import 'package:dev_log/layout/main_content.dart';
import 'package:dev_log/theme/app_theme.dart';

/// The app's home screen: a persistent [Sidebar] with module navigation
/// next to the scrollable [MainContent] dashboard.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: const [
            Sidebar(),
            Expanded(child: MainContent()),
          ],
        ),
      ),
    );
  }
}
