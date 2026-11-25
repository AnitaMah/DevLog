import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors that respond to [AppColors.modeNotifier]. Listen to that notifier
/// at the app root ([DevLogApp]) to rebuild the whole tree when the mode
/// changes — these are plain getters, not part of Flutter's Theme system,
/// so nothing updates automatically just because the value changed.
///
/// Dark-mode values match the "Terminal Dark" design reference exactly.
/// Light mode keeps its prior, simpler palette (not covered by that
/// design) so toggling the theme still works, just without a matching
/// mockup to follow.
class AppColors {
  AppColors._();

  /// True = dark mode (the app's original/default look), false = light.
  static final ValueNotifier<bool> modeNotifier = ValueNotifier<bool>(true);

  static bool get isDark => modeNotifier.value;

  static void setDark(bool value) => modeNotifier.value = value;

  static void toggle() => modeNotifier.value = !modeNotifier.value;

  static Color get background => isDark ? const Color(0xFF0B0D0E) : const Color(0xFFF3F3F5);
  static Color get sidebarBackground => isDark ? const Color(0xFF0E1112) : const Color(0xFFFFFFFF);
  static Color get cardBackground => isDark ? const Color(0xFF121618) : const Color(0xFFFFFFFF);

  /// Visible border (the Terminal Dark reference uses real borders, not a
  /// flat/borderless look).
  static Color get cardBorder => isDark ? const Color(0xFF22282B) : const Color(0xFFE5E5E9);

  /// Border between stacked rows inside a card (e.g. recent-notes list).
  static Color get rowDivider => isDark ? const Color(0xFF1B2022) : const Color(0xFFE2E2E6);

  // Accent: teal, used for links and primary-button fills.
  static const Color accent = Color(0xFF2DD4BF);

  /// Text color used *on* an accent-filled surface (dark-on-teal, not
  /// white-on-teal).
  static const Color accentOnColor = Color(0xFF042F2A);

  /// Muted accent chip pair (e.g. the active sidebar nav link).
  static const Color accentMutedBg = Color(0xFF13302C);
  static const Color accentMutedFg = Color(0xFF5EEAD4);

  // Текст та елементи
  static Color get textPrimary => isDark ? const Color(0xFFE8ECEE) : const Color(0xFF1A1A1E);

  /// Secondary text with more presence (nav links, labels).
  static Color get textSecondary => isDark ? const Color(0xFFB4BDC2) : const Color(0xFF55565C);

  /// Quieter meta text (timestamps, placeholders, hint chips) and
  /// disabled-looking icons.
  static Color get textDisabled => isDark ? const Color(0xFF8D979D) : const Color(0xFFA0A0A6);

  static Color get divider => isDark ? const Color(0xFF1E2326) : const Color(0xFFE2E2E6);

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

  /// Module icon-chip colors (background, foreground), cycling the same
  /// way [tagColorFor] does - matches the Terminal Dark reference's
  /// module cards (teal/amber/purple chips).
  static const List<(Color bg, Color fg)> modulePalette = [
    (Color(0xFF13302C), Color(0xFF5EEAD4)), // teal
    (Color(0xFF33260F), Color(0xFFF5A524)), // amber
    (Color(0xFF251E3B), Color(0xFFA78BFA)), // purple
  ];

  static (Color bg, Color fg) moduleColorFor(String seed) {
    final index = seed.codeUnits.fold<int>(0, (a, b) => a + b) % modulePalette.length;
    return modulePalette[index];
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
  static const double sm = 8.0;
  static const double md = 10.0;
  static const double button = 12.0;
  static const double input = 14.0;
  static const double lg = 16.0;

  /// Fully rounded ("pill") shape for buttons, chips, and nav highlights -
  /// any value at least half the shortest side rounds it completely.
  static const double pill = 999.0;
}

/// Standard square footprints for icon buttons, so every icon button in
/// the app shares one of two consistent sizes instead of each picking its
/// own padding/constraints.
class AppButtonSize {
  /// Compact pill-shaped icon buttons that stand alone in a bar (theme
  /// toggle, grid/list view toggle, top-bar avatar).
  static const double compact = 40.0;

  /// Small trailing action icons on a list row/tile (edit, delete, remove)
  /// - see [AppIconButton].
  static const double small = 28.0;
}

/// Text styles that embed [AppColors], so — like those — these are plain
/// getters rather than compile-time constants, and update whenever the
/// color mode changes.
///
/// Font families follow the Terminal Dark reference: Space Grotesk for
/// headings ([header], [title], [sectionTitle]), Inter for everything
/// else (the default), JetBrains Mono for metadata/code-like text
/// ([mono]) - timestamps, note counts, the "DL" logo mark, kbd hints.
class AppTextStyles {
  static TextStyle get header => GoogleFonts.spaceGrotesk(
      color: AppColors.textPrimary, fontSize: 44, fontWeight: FontWeight.w600, letterSpacing: -0.9, height: 1.1);

  static TextStyle get title => GoogleFonts.spaceGrotesk(
      color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600);

  /// Smaller section heading used for card headers (Recent notes, Popular
  /// tags) - the reference uses 18px there vs. 20px for page sections.
  static TextStyle get sectionTitle => GoogleFonts.spaceGrotesk(
      color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get cardTitle =>
      GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get cardSubtitle =>
      GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.4);

  static TextStyle get body => GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.5);

  static TextStyle get smallText =>
      GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 11, letterSpacing: 0.2);

  /// JetBrains Mono, for metadata/code-like text: timestamps, note
  /// counts, kbd-hint chips, the sidebar's "DL" mark.
  static TextStyle get mono =>
      GoogleFonts.jetBrainsMono(color: AppColors.textDisabled, fontSize: 12, fontWeight: FontWeight.w400);
}
