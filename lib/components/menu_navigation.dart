import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/theme/app_theme.dart';

class MenuNavigation extends StatelessWidget {
  const MenuNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, Box<Module> box, _) {
        final rootModules = box.values.where((m) => m.parentId == null).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: rootModules.length,
          itemBuilder: (context, index) {
            final module = rootModules[index];
            final subModules = box.values.where((m) => m.parentId == module.id).toList();

            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                leading: IconHelper.getFaIcon(
                  module.iconName,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                title: Text(
                  module.title,
                  style: AppTextStyles.cardTitle,
                ),
                children: subModules.map((sub) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 56, right: AppSpacing.lg),
                    dense: true,
                    leading: IconHelper.getFaIcon(
                      sub.iconName,
                      color: AppColors.textDisabled,
                      size: 14,
                    ),
                    title: Text(
                      sub.title,
                      style: AppTextStyles.body,
                    ),
                    onTap: () {
                      // Логіка переходу
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}