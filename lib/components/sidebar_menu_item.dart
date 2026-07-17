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
          
          // Використовуємо Expanded, щоб меню не виходило за межі при великій кількості модулів
          const Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  MenuNavigation(),
                  ModuleList(),
                ],
              ),
            ),
          ),
          
          // Розділювач перед футером для візуального акценту
          const Divider(color: Colors.white10, height: 1),
          
          // Профіль тепер інтегрований у футер
          const SidebarFooter(),
        ],
      ),
    );
  }
}