import 'package:flutter/material.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/helpers/module_actions.dart';
import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/screens/module_details_screen.dart';

/// Renders a submodule row (used inside [ModuleDetailsScreen]'s
/// "Submodules" grid). Tapping opens the submodule's own notes/submodules;
/// the trailing icons let you rename or delete it, since submodules aren't
/// reachable from the dashboard's grid/list views.
class ModuleTile extends StatelessWidget {
  final Module module;

  const ModuleTile({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: ListTile(
        leading: IconHelper.getFaIcon(module.iconName, size: 18, color: AppColors.accentPurple),
        title: Text(module.title, style: AppTextStyles.cardTitle, overflow: TextOverflow.ellipsis),
        subtitle: module.description.isNotEmpty
            ? Text(module.description, style: AppTextStyles.cardSubtitle, overflow: TextOverflow.ellipsis)
            : null,
        onTap: () {
          module.updateLastOpenedAt();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ModuleDetailsScreen(module: module)),
          );
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 14, color: AppColors.textDisabled),
              onPressed: () => showDialog(
                context: context,
                builder: (c) => ModuleInputDialog(module: module, isEditing: true),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 14, color: AppColors.textDisabled),
              onPressed: () => confirmAndDeleteModule(context, module),
            ),
          ],
        ),
      ),
    );
  }
}
