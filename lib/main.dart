import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/theme/app_theme.dart'; // Повний шлях до теми [10-12]
import 'package:dev_log/models/module.dart';
import 'package:dev_log/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ModuleAdapter());
  await Hive.openBox<Module>('modules');
  
  runApp(const DevLogApp());
}

class DevLogApp extends StatelessWidget {
  const DevLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const DashboardScreen(),
    );
  }
}

3. Картка продовження навчання (lib/components/continue_card.dart)
Виправлено помилку з відсутнім параметром timeAgo та додано імпорт теми.

import 'package:flutter/material.dart';
import 'package:dev_log/theme/app_theme.dart'; // Обов'язковий імпорт [17-19]

class ContinueCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeAgo; // Тепер параметр оголошено [13, 14, 16]

  const ContinueCard({
    super.key, 
    required this.title, 
    required this.subtitle, 
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground, // Виправлено з .card [9, 20]
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          Text(subtitle, style: AppTextStyles.body),
          const SizedBox(height: 8),
          Text(timeAgo, style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}
