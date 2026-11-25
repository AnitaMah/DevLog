import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/database/database_helper.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/models/user_model.dart';
import 'package:dev_log/components/edit_profile_screen.dart';
import 'package:dev_log/screens/module_details_screen.dart';
import 'package:dev_log/theme/app_theme.dart';

const _navIcons = [
  (Icons.home_outlined, Icons.home, "Home"),
  (Icons.work_outline, Icons.work, "Projects"),
  (Icons.description_outlined, Icons.description, "Notes"),
  (Icons.label_outline, Icons.label, "Tags"),
];

/// Left sidebar matching the "Terminal Dark" design reference: logo, a
/// search button (jumps to the Notes tab's search field rather than
/// filtering in place), the 4 main nav links, a live list of root
/// modules, and a footer (Settings link + avatar/name + theme toggle).
class Sidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;
  final VoidCallback onSearchTap;

  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onIndexSelected,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppGlass.panelBackground,
            border: Border(right: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        "DL",
                        style: AppTextStyles.mono.copyWith(
                          color: AppColors.accentOnColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      "DevLog",
                      style: AppTextStyles.sectionTitle.copyWith(
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SearchButton(onTap: onSearchTap),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < _navIcons.length; i++)
                _NavItem(
                  icon: currentIndex == i ? _navIcons[i].$2 : _navIcons[i].$1,
                  label: _navIcons[i].$3,
                  selected: currentIndex == i,
                  onTap: () => onIndexSelected(i),
                ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "MODULES",
                        style: AppTextStyles.mono.copyWith(
                          letterSpacing: 1.2,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const ModuleInputDialog(),
                      ),
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<Module>('modules').listenable(),
                  builder: (context, Box<Module> box, _) {
                    final modules = DatabaseHelper.getRootModules();
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: modules
                          .map(
                            (m) => _ModuleItem(
                              module: m,
                              onTap: () {
                                m.updateLastOpenedAt();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ModuleDetailsScreen(module: m),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NavItem(
                      icon: currentIndex == 4
                          ? Icons.settings
                          : Icons.settings_outlined,
                      label: "Settings",
                      selected: currentIndex == 4,
                      onTap: () => onIndexSelected(4),
                    ),
                    const _SidebarFooterRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      hoverColor: AppColors.isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
      child: Container(
        // Sized by content + padding, matching the mockup's `.side-search`
        // (no fixed height there) - noticeably shorter than a 44px nav row.
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 16, color: AppColors.textDisabled),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text("Search notes", style: AppTextStyles.body)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Ctrl K",
                style: AppTextStyles.mono.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentMutedBg : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? AppColors.accentMutedFg
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.accentMutedFg
                    : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleItem extends StatelessWidget {
  final Module module;
  final VoidCallback onTap;
  const _ModuleItem({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (_, fg) = AppColors.moduleColorFor(module.title);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: fg,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                module.title,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarFooterRow extends StatelessWidget {
  const _SidebarFooterRow();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<UserModel>('userBox').listenable(),
      builder: (context, Box<UserModel> box, _) {
        final user = box.isNotEmpty
            ? box.getAt(0)!
            : UserModel(
                name: "User",
                email: "",
                avatarPath: 'assets/images/default_avatar.png',
              );
        final hasCustomAvatar =
            user.avatarPath != 'assets/images/default_avatar.png';
        final file = File(user.avatarPath);
        final fileExists = hasCustomAvatar && file.existsSync();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.cardBackground,
                        backgroundImage: fileExists ? FileImage(file) : null,
                        child: !fileExists
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : "?",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppIconButtonSquare(
                icon: AppColors.isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                onPressed: () {
                  AppColors.toggle();
                  DatabaseHelper.saveThemePreference(AppColors.isDark);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A bordered square icon button (distinct from the pill-shaped
/// [AppButtonSize.compact] buttons elsewhere) - matches the Terminal Dark
/// reference's theme-toggle button style.
class AppIconButtonSquare extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const AppIconButtonSquare({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}
