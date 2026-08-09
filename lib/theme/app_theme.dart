import 'package:flutter/material.dart';

/// Colors that respond to [AppColors.modeNotifier]. Listen to that notifier
/// at the app root ([DevLogApp]) to rebuild the whole tree when the mode
/// changes — these are plain getters, not part of Flutter's Theme system,
/// so nothing updates automatically just because the value changed.
class AppColors {
  AppColors._();

  /// True = dark mode (the app's original/default look), false = light.
  static final ValueNotifier<bool> modeNotifier = ValueNotifier<bool>(true);

  static bool get isDark => modeNotifier.value;

  static void setDark(bool value) => modeNotifier.value = value;

  static void toggle() => modeNotifier.value = !modeNotifier.value;

  // Основна палітра
  static Color get background =>
      isDark ? const Color(0xFF0F0F11) : const Color(0xFFF3F3F5);
  static Color get sidebarBackground =>
      isDark ? const Color(0xFF161618) : const Color(0xFFFFFFFF);
  static Color get cardBackground =>
      isDark ? const Color(0xFF1E1E21) : const Color(0xFFFFFFFF);

  /// Subtle border around cards — visible dark-on-light in light mode
  /// instead of the barely-there white-on-dark hairline.
  static Color get cardBorder =>
      isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE5E5E9);

  // Акцентні кольори — залишаються однаковими в обох темах
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentPurpleLight = Color(0xFF9575CD);

  // Текст та елементи
  static Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A1A1E);
  static Color get textSecondary => isDark ? Colors.white70 : const Color(0xFF55565C);
  static Color get textDisabled => isDark ? Colors.white30 : const Color(0xFFA0A0A6);
  static Color get divider => isDark ? Colors.white10 : const Color(0xFFE2E2E6);

  // Палітра для тегів/міток (циклічна) — залишається однаковою в обох темах
  static const List<Color> tagPalette = [
    Color(0xFF7C4DFF), // purple
    Color(0xFF4CAF93), // green
    Color(0xFF29B6F6), // blue
    Color(0xFFFFA726), // orange
    Color(0xFFEF5DA8), // pink
    Color(0xFF26A69A), // teal
  ];

  static Color tagColorFor(String seed) {
    final index = seed.codeUnits.fold<int>(0, (a, b) => a + b) % tagPalette.length;
    return tagPalette[index];
  }
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppRadius {
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
}

/// Text styles that embed [AppColors], so — like those — these are plain
/// getters rather than compile-time constants, and update whenever the
/// color mode changes.
class AppTextStyles {
  static TextStyle get header =>
      TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold);

  static TextStyle get title =>
      TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get cardTitle =>
      TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold);

  static TextStyle get cardSubtitle =>
      TextStyle(color: AppColors.textSecondary, fontSize: 12);

  static TextStyle get body =>
      TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5);

  static TextStyle get smallText =>
      TextStyle(color: AppColors.textDisabled, fontSize: 11);
}
