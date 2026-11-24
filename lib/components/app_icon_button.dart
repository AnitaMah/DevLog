import 'package:flutter/material.dart';

import 'package:dev_log/theme/app_theme.dart';

/// A small trailing action icon (edit, delete, remove, clear) with a fixed
/// [AppButtonSize.small] footprint - used everywhere a list row/tile needs
/// a compact icon button, so they're all the same size instead of each
/// call site picking its own padding/icon size.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppButtonSize.small,
      height: AppButtonSize.small,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: iconSize, color: color ?? AppColors.textDisabled),
        onPressed: onPressed,
      ),
    );
  }
}
