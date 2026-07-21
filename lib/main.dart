import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/submodule.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:dev_log/screens/home_screen.dart'; // <-- Переконайтеся, що цей імпорт є
import 'package:dev_log/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init(); // Ініціалізація Hive
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
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      home: const HomeScreen(), // <-- Головний екран
    );
  }
}
