import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(),
          SizedBox(width: 10),
          Text("User", style: AppTextStyles.body),
        ],
      ),
    );
  }
}