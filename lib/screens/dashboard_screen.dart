import 'package:flutter/material.dart';
import '../layout/sidebar.dart'; // Імпортуємо сайдбар
import '../layout/main_content.dart'; // Імпортуємо контент

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Темний фон з вашого макету
      body: Row(
        children: [
          const Sidebar(), // Фіксована ширина зліва [cite: 11]
          const Expanded(
            child: MainContent(), // Займає весь решту простору 
          ),
        ],
      ),
    );
  }
}