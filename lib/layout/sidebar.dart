import 'package:flutter/material.dart';

import '../components/header_logo_section.dart';
import '../components/search_bar_widget.dart';
import '../components/menu_navigation.dart';
import '../components/module_list.dart';
import '../components/sidebar_footer.dart';

import '../theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.sidebarBackground,
      child: Column(
        children: [ // ВИДАЛЕНО const ПЕРЕД СПИСКОМ [1, 4, 5]
          HeaderLogoSection(),
          SearchBarWidget(),
          MenuNavigation(),
          ModuleList(), // Тепер може завантажувати дані з Hive [6, 7]
          const Spacer(),
          SidebarFooter(), // Тепер інтерактивний та підключений до Hive [8, 9]
        ],
      ),
    );
  }
}