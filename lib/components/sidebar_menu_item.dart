import 'package:flutter/material.dart';

// Імпортуйте файл, де знаходиться ваш EditProfileScreen
import '../screens/edit_profile_screen.dart'; 

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
        // Прибрано 'const', оскільки тепер тут є динамічний ListTile
        children: [
          const HeaderLogoSection(),
          const SearchBarWidget(),
          const MenuNavigation(),
          const ModuleList(),
          
          // Додаємо ListTile сюди
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Edit Profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          
          const Spacer(),
          const SidebarFooter(),
        ],
      ),
    );
  }
}