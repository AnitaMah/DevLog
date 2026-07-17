import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:dev_log/screens/dashboard_screen.dart';
import 'package:dev_log/theme/app_theme.dart';

void main() async {
  // 1. Обов'язково для ініціалізації Flutter-біндінгів
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Ініціалізація Hive
  await Hive.initFlutter();

  // 3. Реєстрація адаптерів
  // Важливо: ці адаптери створюються автоматично командою 'flutter pub run build_runner build'
  Hive.registerAdapter(ModuleAdapter()); 
  Hive.registerAdapter(UserModelAdapter());

  // 4. ВІДКРИТТЯ БОКСІВ
  await Hive.openBox<Module>('modules');
  await Hive.openBox<UserModel>('userBox');

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