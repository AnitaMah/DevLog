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
          padding: const EdgeInsets.all(10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
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
        // Mirrors the mockup's three large `radial-gradient(...at x% y%,
        // color, transparent N%)` washes on body::before - broad, soft
        // ellipses, not tight glowing dots, so they actually read through
        // the glass panels sitting on top of them.
        _radialWash(
          center: const Alignment(-0.7, -1.2),
          color: const Color(0xFFFFD696),
          alpha: 0.16,
          radius: 1.3,
        ),
        _radialWash(
          center: const Alignment(0.85, -1.0),
          color: AppColors.accent,
          alpha: 0.14,
          radius: 1.1,
        ),
        _radialWash(
          center: const Alignment(0.0, 1.3),
          color: const Color(0xFF9C7850),
          alpha: 0.22,
          radius: 1.6,
        ),
      ],
    );
  }

  static Widget _radialWash({
    required Alignment center,
    required Color color,
    required double alpha,
    required double radius,
  }) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center,
            radius: radius,
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
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
