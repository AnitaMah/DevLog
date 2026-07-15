import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Важливо: використовуйте назву проекту малими літерами (dev_log) [12-14]
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:dev_log/screens/dashboard_screen.dart';

void main() async {
  // Гарантуємо ініціалізацію фреймворку перед запуском Hive [8, 11]
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ініціалізація Hive для Flutter
  await Hive.initFlutter();
  
  // Реєстрація адаптерів для збереження ваших моделей у БД [8, 10]
  Hive.registerAdapter(ModuleAdapter());
  Hive.registerAdapter(UserModelAdapter());
  
  // Відкриття "коробок" (boxes) для даних
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
      // Налаштування темного оформлення згідно з вашим макетом [11, 15]
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: AppColors.textWhite,
        ),
      ),
      // Головний екран — "скелет" вашого додатку [9, 16]
      home: const DashboardScreen(),
    );
  }
}