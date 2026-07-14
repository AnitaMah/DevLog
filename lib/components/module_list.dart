import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModuleList extends StatelessWidget {
  const ModuleList({super.key});

  static const modules = [
    "C Basics",
    "C Piscine",
    "Algorithms",
    "Data Structures",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text("MODULES", style: AppTextStyles.small),
        ),
        ...modules.map(
          (m) => ListTile(
            title: Text(m, style: AppTextStyles.body),
          ),
        ),
      ],
    );
  }
}