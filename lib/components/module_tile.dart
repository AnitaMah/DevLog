import 'package:flutter/material.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/theme/app_theme.dart';
import 'package:dev_log/helpers/icon_helper.dart';
import 'package:dev_log/helpers/module_actions.dart';
import 'package:dev_log/components/app_icon_button.dart';
import 'package:dev_log/components/module_input_dialog.dart';
import 'package:dev_log/components/project_status_badge.dart';
import 'package:dev_log/screens/module_details_screen.dart';

/// Renders a submodule row (used inside [ModuleDetailsScreen]'s
/// "Submodules" grid). Tapping opens the submodule's own notes/submodules;
/// the trailing icons let you rename or delete it. (The dashboard's
/// "Projects" section uses the bolder [ProjectHeroCard] instead.)
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
        leading: IconHelper.getFaIcon(module.iconName, size: 18, color: AppColors.accent),
        title: Row(
          children: [
            Flexible(
              child: Text(module.title, style: AppTextStyles.cardTitle, overflow: TextOverflow.ellipsis),
            ),
            if (module.isProject) ...[
              const SizedBox(width: 6),
              ProjectStatusBadge(status: module.status, completionPercent: module.taskCompletionPercent),
            ],
          ],
        ),
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
            AppIconButton(
              icon: Icons.edit_outlined,
              onPressed: () => showDialog(
                context: context,
                builder: (c) => ModuleInputDialog(module: module, isEditing: true),
              ),
            ),
            AppIconButton(
              icon: Icons.close,
              onPressed: () => confirmAndDeleteModule(context, module),
            ),
          ],
        ),
      ),
    );
  }
}
