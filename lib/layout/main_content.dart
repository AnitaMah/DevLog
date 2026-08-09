import 'package:flutter/material.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/components/main_top_bar.dart';
import 'package:dev_log/components/module_grid.dart';
import 'package:dev_log/components/module_list_view.dart';
import 'package:dev_log/components/recent_modules_section.dart';
import 'package:dev_log/components/recent_notes_panel.dart';
import 'package:dev_log/components/popular_tags_panel.dart';

class MainContent extends StatefulWidget {
  const MainContent({super.key});

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MainTopBar(),
          const SizedBox(height: 40),

          // Динамічна секція останніх модулів
          const RecentModulesSection(),

          const SizedBox(height: 40),

          // Секція модулів
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Your Modules", style: AppTextStyles.title),
                Row(
                  children: [
                    _ViewToggleButton(
                      icon: Icons.grid_view_rounded,
                      selected: _isGridView,
                      onTap: () => setState(() => _isGridView = true),
                    ),
                    const SizedBox(width: 4),
                    _ViewToggleButton(
                      icon: Icons.view_list_rounded,
                      selected: !_isGridView,
                      onTap: () => setState(() => _isGridView = false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _isGridView ? const ModuleGrid() : const ModuleListView(),

          const SizedBox(height: 40),

          // Recent Notes + Popular Tags
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 640;
              final recentNotes = const RecentNotesPanel();
              final popularTags = const PopularTagsPanel();

              if (isNarrow) {
                return Column(
                  children: [
                    recentNotes,
                    const SizedBox(height: 16),
                    popularTags,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: recentNotes),
                  const SizedBox(width: 16),
                  Expanded(child: popularTags),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPurple : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
      ),
    );
  }
}
