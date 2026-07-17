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
        children: [
          const HeaderLogoSection(),
          const SearchBarWidget(),
          const Expanded( // Використовуємо Expanded, щоб меню займало весь простір
            child: SingleChildScrollView(
              child: Column(
                children: [
                  MenuNavigation(),
                  ModuleList(),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white10), // Розділювач перед футером
          const SidebarFooter(),
        ],
      ),
    );
  }
}