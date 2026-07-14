import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeaderLogoSection extends StatelessWidget {
  const HeaderLogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        "42 Guides",
        style: AppTextStyles.header,
      ),
    );
  }
}