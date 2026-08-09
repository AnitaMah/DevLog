import 'package:flutter/material.dart';
import '../components/header_logo_section.dart';
import '../components/search_bar_widget.dart';
import '../components/search_results_list.dart';
import '../components/menu_navigation.dart';
import '../components/sidebar_footer.dart';
import '../theme/app_theme.dart';

class Sidebar extends StatefulWidget {
  final FocusNode? searchFocusNode;

  const Sidebar({super.key, this.searchFocusNode});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.trim().isNotEmpty;

    // Material (not a plain colored Container) so the ListTiles below -
    // the module tree, search results, etc. - have a Material ancestor to
    // paint their ink splashes on without an opaque box in the way.
    return SizedBox(
      width: 280,
      child: Material(
        color: AppColors.sidebarBackground,
        child: Column(
          children: [
            const HeaderLogoSection(),
            SearchBarWidget(
              focusNode: widget.searchFocusNode,
              onChanged: (value) => setState(() => _query = value),
            ),
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
            Divider(color: AppColors.divider), // Розділювач перед футером
            const SidebarFooter(),
          ],
        ),
      ),
    );
  }
}
