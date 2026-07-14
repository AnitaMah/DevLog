import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MenuNavigation extends StatelessWidget {
  const MenuNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ListTile(title: Text("Home", style: AppTextStyles.body)),
        ListTile(title: Text("All Guides", style: AppTextStyles.body)),
        ListTile(title: Text("Progress", style: AppTextStyles.body)),
      ],
    );
  }
}