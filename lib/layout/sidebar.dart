import 'package:flutter/material.dart';
import '../components/header_logo_section.dart';
import '../components/search_bar_widget.dart';
import '../components/search_results_list.dart';
import '../components/menu_navigation.dart';
import '../components/sidebar_footer.dart';
import '../theme/app_theme.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.trim().isNotEmpty;

    return Container(
      width: 280,
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          const HeaderLogoSection(),
          SearchBarWidget(onChanged: (value) => setState(() => _query = value)),
          Expanded( // Використовуємо Expanded, щоб меню займало весь простір
            child: SingleChildScrollView(
              child: isSearching
                  ? SearchResultsList(query: _query)
                  : const Column(
                      children: [
                        MenuNavigation(),
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
