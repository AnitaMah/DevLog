import 'dart:ui' as ui show Gradient;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:dev_log/theme/app_theme.dart';

/// The "mixed reality" frame around the whole app from the 2026-11-25
/// Variant A mockup: a floating window (chrome bar + gesture legend) that
/// appears to sit in a physical room, rather than filling the screen.
///
/// [child] is the app's normal content (sidebar + body) - this only adds
/// the chrome above it and the gesture bar below it, inside one floating,
/// rounded, shadowed panel over [RoomPassthrough].
class SpatialShell extends StatefulWidget {
  final Widget child;
  const SpatialShell({super.key, required this.child});

  @override
  State<SpatialShell> createState() => _SpatialShellState();
}

class _SpatialShellState extends State<SpatialShell> {
  final ValueNotifier<Offset?> _cursor = ValueNotifier(null);

  @override
  void dispose() {
    _cursor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: RoomPassthrough()),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: AppColors.isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 100,
                        offset: const Offset(0, 50),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              // No opaque fill of its own - [RoomPassthrough] shows
              // straight through everywhere the app doesn't cover with
              // its own (glass) surfaces, same as the mockup's
              // `.app`/`.content` having no background of their own.
              // (RoomPassthrough itself falls back to a flat
              // AppColors.background in light mode.)
              child: MouseRegion(
                onHover: (e) => _cursor.value = e.localPosition,
                onExit: (_) => _cursor.value = null,
                child: Stack(
                  children: [
                    // The mockup's `.liquid-light` - a soft white glow
                    // that follows the cursor, sitting BEHIND the chrome
                    // and content so the glass panels' own blur picks it
                    // up (same z-order as `.liquid-light`'s z-index:0 vs.
                    // `.window-chrome`/`.app`'s z-index:1).
                    ValueListenableBuilder<Offset?>(
                      valueListenable: _cursor,
                      builder: (context, cursor, _) =>
                          _LiquidLight(cursor: cursor),
                    ),
                    Column(
                      children: [
                        const _WindowChrome(),
                        Expanded(child: widget.child),
                        const _GestureBar(),
                        const _WindowGrabBar(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A soft, cursor-following radial highlight - mirrors the mockup's
/// `.liquid-light` (a radial gradient centered on the mouse position,
/// white fading to transparent). Purely decorative, dark-mode only.
class _LiquidLight extends StatelessWidget {
  final Offset? cursor;
  const _LiquidLight({required this.cursor});

  @override
  Widget build(BuildContext context) {
    if (cursor == null || !AppColors.isDark) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _LiquidLightPainter(cursor!),
      ),
    );
  }
}

class _LiquidLightPainter extends CustomPainter {
  final Offset center;
  const _LiquidLightPainter(this.center);

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 460.0;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.09),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.62],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidLightPainter oldDelegate) =>
      oldDelegate.center != center;
}

/// The room the spatial window floats in - a few soft, blurred glows over
/// a dark gradient, only shown in dark mode (the mockup has no light-mode
/// equivalent, like the rest of this redesign).
class RoomPassthrough extends StatelessWidget {
  const RoomPassthrough({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppColors.isDark) return ColoredBox(color: AppColors.background);
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF14110D), Color(0xFF0C0E0F), Color(0xFF0A0D0E)],
              stops: [0.0, 0.42, 1.0],
            ),
          ),
        ),
        // Mirrors the mockup's three `radial-gradient(900px 500px at 14%
        // -10%, color, transparent 55%)`-style washes on body::before -
        // CSS sizes those in FIXED pixels at a PERCENTAGE position, so they
        // stay the same size regardless of window size (a maximized desktop
        // window doesn't balloon them the way a widget-relative radius
        // would). Painted directly so size and position follow that exact
        // rule instead of scaling with the widget's own bounds.
        const IgnorePointer(
          child: CustomPaint(size: Size.infinite, painter: _RoomGlowPainter()),
        ),
      ],
    );
  }
}

class _RoomGlowPainter extends CustomPainter {
  const _RoomGlowPainter();

  // (centerXPct, centerYPct, radiusXPx, radiusYPx, color, alpha, transparentAtFraction)
  // CSS also applies `saturate(115%)` to the whole wash layer, making it
  // read more vivid than the raw rgba alpha alone - compensated here with
  // higher alpha and reach (more of the washes' bright core sits inside the
  // window) rather than replicating the saturation filter itself.
  static const _washes = [
    (0.14, 0.05, 900.0, 650.0, Color(0xFFFFD696), 0.26, 0.6),
    (0.92, 0.08, 700.0, 650.0, AppColors.accent, 0.2, 0.62),
    (0.50, 0.95, 1000.0, 600.0, Color(0xFF9C7850), 0.3, 0.65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (cxPct, cyPct, rx, ry, color, alpha, stop) in _washes) {
      final center = Offset(size.width * cxPct, size.height * cyPct);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1.0, ry / rx);
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          rx,
          [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          [0.0, stop],
        );
      canvas.drawCircle(Offset.zero, rx, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RoomGlowPainter oldDelegate) => false;
}

class _WindowChrome extends StatelessWidget {
  const _WindowChrome();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.ink950.withValues(alpha: 0.75),
            border: Border(bottom: BorderSide(color: AppColors.lineSoft)),
          ),
          child: Row(
            children: [
              _dot(),
              const SizedBox(width: 6),
              _dot(),
              const SizedBox(width: 6),
              _dot(),
              const SizedBox(width: 10),
              Text(
                'DevLog — spatial window',
                style: AppTextStyles.mono.copyWith(
                  fontSize: 11.5,
                  color: AppColors.textDisabled,
                ),
              ),
              const Spacer(),
              const AnchorBadge(label: 'Pinned in room'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot() => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.ink700,
      border: Border.all(color: AppColors.lineSoft),
    ),
  );
}

class _GestureBar extends StatelessWidget {
  const _GestureBar();

  static const _items = [
    ('👁', 'Gaze', 'focus'),
    ('🤏', 'Pinch', 'select'),
    ('🎙', '"New note"', 'voice'),
    ('↻', 'Wrist rotate', 'zoom (Neural Band)'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.ink950.withValues(alpha: 0.7),
            border: Border(top: BorderSide(color: AppColors.lineSoft)),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 4,
            children: [
              for (final (emoji, label, rest) in _items)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$emoji '),
                      TextSpan(
                        text: label,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' — $rest'),
                    ],
                  ),
                  style: AppTextStyles.mono.copyWith(fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowGrabBar extends StatelessWidget {
  const _WindowGrabBar();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: Container(
          height: 10,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.ink950.withValues(alpha: 0.75),
            border: Border(top: BorderSide(color: AppColors.lineSoft)),
          ),
          child: Container(
            width: 64,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
