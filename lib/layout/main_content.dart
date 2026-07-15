import 'package:flutter/material.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/continue_card.dart';
import 'package:dev_log/components/module_grid.dart';

class MainContent extends StatelessWidget {
  const MainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome back, Anita 👋", style: AppTextStyles.header),
          const Text("“Knowledge is organized experience.” — 42", style: AppTextStyles.body),
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Continue where you left off", style: AppTextStyles.title),
              Text("View all", style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.accentPurple)),
            ],
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                // Важливо: видалено const у батьківських елементах для динамічних даних [6, 12, 13]
                ContinueCard(
                  title: "Pointers in C", 
                  subtitle: "C Basics", 
                  description: "Understand pointers, memory addresses and how they work...", 
                  timeAgo: "5 min ago"
                ),
                SizedBox(width: 16),
                ContinueCard(
                  title: "Unix Basics", 
                  subtitle: "Unix", 
                  description: "Learn the most important Unix commands that every student must know.", 
                  timeAgo: "1 day ago"
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          Text("Your Modules", style: AppTextStyles.title),
          const SizedBox(height: 16),
          const ModuleGrid(), // Виклик вашої сітки [14]
        ],
      ),
    );
  }
}