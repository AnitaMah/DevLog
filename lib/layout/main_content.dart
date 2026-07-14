import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Імпортуємо тему
import '../components/continue_card.dart';
import '../components/module_grid.dart'; // Імпортуємо сітку модулів

class MainContent extends StatelessWidget {
  const MainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Додаємо прокрутку для всієї сторінки
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Continue where you left off", style: AppStyles.title),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                ContinueCard(title: "Pointers in C", subtitle: "C Basics", timeAgo: "5 min ago"),
                ContinueCard(title: "Unix Basics", subtitle: "Unix", timeAgo: "1 day ago"),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text("Your Modules", style: AppStyles.title),
          const SizedBox(height: 16),
          ModuleGrid(), // Додана сітка модулів
        ],
      ),
    );
  }
}