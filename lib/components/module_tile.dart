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
/// the trailing icons let you rename or delete it. Styled as a glass card
/// to match the Terminal Dark + Spatial mockup's module cards (e.g. Home's
/// module grid), rather than a flat list row.
class ModuleTile extends StatelessWidget {
  final Module module;

  const ModuleTile({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.moduleColorFor(module.title);

    return GlassPanel(
      child: InkWell(
        onTap: () {
          module.updateLastOpenedAt();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ModuleDetailsScreen(module: module)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: IconHelper.getFaIcon(module.iconName, size: 16, color: fg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            module.title,
                            style: AppTextStyles.cardTitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (module.isProject) ...[
                          const SizedBox(width: 6),
                          ProjectStatusBadge(
                            status: module.status,
                            completionPercent: module.taskCompletionPercent,
                          ),
                        ],
                      ],
                    ),
                    if (module.description.isNotEmpty)
                      Text(
                        module.description,
                        style: AppTextStyles.cardSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
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
      ),
    );
  }
}
