import 'dart:ui' show ImageFilter;

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

  static Color get background =>
      isDark ? const Color(0xFF0B0D0E) : const Color(0xFFF3F3F5);
  static Color get sidebarBackground =>
      isDark ? const Color(0xFF0E1112) : const Color(0xFFFFFFFF);
  static Color get cardBackground =>
      isDark ? const Color(0xFF121618) : const Color(0xFFFFFFFF);

  /// Visible border (the Terminal Dark reference uses real borders, not a
  /// flat/borderless look).
  static Color get cardBorder =>
      isDark ? const Color(0xFF22282B) : const Color(0xFFE5E5E9);

  /// Border between stacked rows inside a card (e.g. recent-notes list).
  static Color get rowDivider =>
      isDark ? const Color(0xFF1B2022) : const Color(0xFFE2E2E6);

  // Accent: teal, used for links and primary-button fills.
  static const Color accent = Color(0xFF2DD4BF);

  /// Text color used *on* an accent-filled surface (dark-on-teal, not
  /// white-on-teal).
  static const Color accentOnColor = Color(0xFF042F2A);

  /// Muted accent chip pair (e.g. the active sidebar nav link).
  static const Color accentMutedBg = Color(0xFF13302C);
  static const Color accentMutedFg = Color(0xFF5EEAD4);

  // Текст та елементи
  static Color get textPrimary =>
      isDark ? const Color(0xFFE8ECEE) : const Color(0xFF1A1A1E);

  /// Secondary text with more presence (nav links, labels).
  static Color get textSecondary =>
      isDark ? const Color(0xFFB4BDC2) : const Color(0xFF55565C);

  /// Quieter meta text (timestamps, placeholders, hint chips) and
  /// disabled-looking icons.
  static Color get textDisabled =>
      isDark ? const Color(0xFF8D979D) : const Color(0xFFA0A0A6);

  static Color get divider =>
      isDark ? const Color(0xFF1E2326) : const Color(0xFFE2E2E6);

  // --- Spatial UI / Liquid Glass reference (2026-11-25 mockup) ---
  // Dark-only decorative tones for the floating window chrome and the
  // "room passthrough" the glass panels sit over - the mockup only
  // defines these for Terminal Dark, so they're plain consts rather than
  // isDark-switched getters like the rest of this file.
  static const Color ink950 = Color(0xFF0A0D0E);
  static const Color ink900 = Color(0xFF0D1113);
  static const Color ink800 = Color(0xFF121719);
  static const Color ink700 = Color(0xFF171D1F);
  static const Color lineSoft = Color(0xFF161C1E);

  static const Color amber = Color(0xFFE2922F);
  static const Color amberBg = Color(0x24E2922F);
  static const Color violet = Color(0xFFA78BFA);
  static const Color violetBg = Color(0x24A78BFA);
  static const Color danger = Color(0xFFF87171);
  static const Color dangerBg = Color(0x1FF87171);

  /// Mint-tinted pill used for the anchor badge and active-nav highlight
  /// in the spatial shell (border + fill + foreground).
  static const Color anchorBg = Color(0x1F2DD4BF);
  static const Color anchorBorder = Color(0x4D2DD4BF);
  static const Color anchorFg = Color(0xFF5EEAD4);

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
    final index =
        seed.codeUnits.fold<int>(0, (a, b) => a + b) % tagPalette.length;
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
    final index =
        seed.codeUnits.fold<int>(0, (a, b) => a + b) % modulePalette.length;
    return modulePalette[index];
  }
}

/// Translucent "glass" surfaces for the Variant A spatial redesign - panels
/// that sit above the app's flat background with a blurred, semi-opaque
/// fill instead of a solid card color.
class AppGlass {
  AppGlass._();

  static const double blurSigma = 16.0;

  static Color get panelBackground =>
      (AppColors.isDark ? AppColors.ink700 : Colors.white).withValues(
        alpha: 0.72,
      );

  static Color get panelBorder =>
      (AppColors.isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
}

/// A blurred, semi-opaque surface over whatever sits behind it in the
/// widget tree - the "glass" card/panel look from the Variant A spatial
/// redesign. Pass [borderRadius] matching the shape you need (a pill-ish
/// card vs. a full-height sidebar edge) and put the real content as
/// [child]; this widget only supplies the backdrop blur, fill, and border.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Border? border;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.lg)),
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppGlass.panelBackground,
            borderRadius: borderRadius,
            border: border ?? Border.all(color: AppGlass.panelBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Diagonal light sweep across [child] on hover - the mockup's
/// `.liquid-sheen` effect, used on primary/interactive controls (buttons,
/// the sidebar search field). Purely decorative: the sweep band fades in
/// from one side and back out, driven by hover enter/exit.
class LiquidSheen extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  const LiquidSheen({super.key, required this.child, this.borderRadius});

  @override
  State<LiquidSheen> createState() => _LiquidSheenState();
}

class _LiquidSheenState extends State<LiquidSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bandWidth = constraints.maxWidth * 0.4;
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final t = Curves.easeOutCubic.transform(
                          _controller.value,
                        );
                        final dx =
                            -bandWidth +
                            (constraints.maxWidth + bandWidth * 2) * t;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: Transform.rotate(
                            angle: 0.14, // ~8deg, matching the mockup's skew
                            child: Container(
                              width: bandWidth,
                              height: constraints.maxHeight * 2.2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mint pill with a pin icon - the mockup's "persists in the room even
/// when the device is off" badge, shown on the window chrome and on
/// anything pinned in the spatial shell (e.g. the quick-capture bar).
class AnchorBadge extends StatelessWidget {
  final String label;
  const AnchorBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.anchorBg,
        border: Border.all(color: AppColors.anchorBorder),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 11, color: AppColors.anchorFg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.anchorFg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
    color: AppColors.textPrimary,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.9,
    height: 1.1,
  );

  static TextStyle get title => GoogleFonts.spaceGrotesk(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  /// Smaller section heading used for card headers (Recent notes, Popular
  /// tags) - the reference uses 18px there vs. 20px for page sections.
  static TextStyle get sectionTitle => GoogleFonts.spaceGrotesk(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get cardTitle => GoogleFonts.inter(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get cardSubtitle => GoogleFonts.inter(
    color: AppColors.textSecondary,
    fontSize: 12,
    height: 1.4,
  );

  static TextStyle get body => GoogleFonts.inter(
    color: AppColors.textSecondary,
    fontSize: 13,
    height: 1.5,
  );

  static TextStyle get smallText => GoogleFonts.inter(
    color: AppColors.textDisabled,
    fontSize: 11,
    letterSpacing: 0.2,
  );

  /// JetBrains Mono, for metadata/code-like text: timestamps, note
  /// counts, kbd-hint chips, the sidebar's "DL" mark.
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    color: AppColors.textDisabled,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}
