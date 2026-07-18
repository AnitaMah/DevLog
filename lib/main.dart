import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/submodule.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:dev_log/screens/dashboard_screen.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();
  runApp(const DevLogApp());
}

class DevLogApp extends StatelessWidget {
  const DevLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DevLog',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentPurple,
          surface: AppColors.background,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
