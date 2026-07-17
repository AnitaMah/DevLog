import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Helper class for managing module icons.
/// Provides a centralized way to get FontAwesome icons by name.
class IconHelper {
  /// Map of icon names to their corresponding [FaIconData].
  static const Map<String, FaIconData> icons = {
    'code': FontAwesomeIcons.code,
    'c': FontAwesomeIcons.c,
    'git': FontAwesomeIcons.git,
    'docker': FontAwesomeIcons.docker,
    'python': FontAwesomeIcons.python,
    'dart': FontAwesomeIcons.dartLang,
    'flutter': FontAwesomeIcons.flutter,
    'folder': FontAwesomeIcons.folder,
    'terminal': FontAwesomeIcons.terminal,
    'linux': FontAwesomeIcons.linux,
    'database': FontAwesomeIcons.database,
    'book': FontAwesomeIcons.book, // Додано для нотаток
    'gear': FontAwesomeIcons.gear, // Додано для налаштувань
    'pen': FontAwesomeIcons.pen,   // Додано для редагування
  };

  /// Returns the [FaIconData] for the given icon name.
  /// If the icon is not found, returns [FontAwesomeIcons.folder] as a fallback.
  static FaIconData getIcon(String? name) {
    return icons[name] ?? FontAwesomeIcons.folder;
  }

  /// Returns a [FaIcon] widget for the given icon name.
  /// Used for convenience in widgets.
  static Widget getFaIcon(String? name, {double size = 24, Color? color}) {
    return FaIcon(
      getIcon(name),
      size: size,
      color: color,
    );
  }
}