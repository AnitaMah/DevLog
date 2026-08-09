import 'package:flutter/material.dart';
import 'package:dev_log/screens/dashboard_screen.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();
  runApp(const DevLogApp());
}

class DevLogApp extends StatelessWidget {
  const DevLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole tree whenever AppColors.toggle()/setDark() is
    // called, so every widget re-reads the (non-const) AppColors getters.
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.modeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '42 Guides',
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.sidebarBackground,
              titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 20),
            ),
          ),
          home: const DashboardScreen(),
        );
      },
    );
  }
}
