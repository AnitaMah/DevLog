// 1. Усі імпорти мають бути на самому початку
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

// Імпорти ваших локальних файлів
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:dev_log/screens/dashboard_screen.dart';

// 2. Потім іде функція main
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDir = await getApplicationDocumentsDirectory();
  final hivePath = path.join(appDir.path, 'dev_log_data');

  final dir = Directory(hivePath);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  try {
    await Hive.initFlutter(hivePath);

    Hive.registerAdapter(ModuleAdapter());
    Hive.registerAdapter(UserModelAdapter());

    await Hive.openBox<Module>('modules');
    await Hive.openBox<UserModel>('userBox');

    runApp(const DevLogApp());
  } catch (e) {
    debugPrint("Error initializing Hive: $e");
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text("Failed to initialize app data. Please restart the app."),
          ),
        ),
      ),
    );
  }
}

// 3. Потім ідуть класи (наприклад, DevLogApp)
class DevLogApp extends StatelessWidget {
  const DevLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DevLog',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DashboardScreen(),
    );
  }
}