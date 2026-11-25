import 'package:flutter/material.dart';

import 'package:dev_log/theme/app_theme.dart';

/// The "mixed reality" frame around the whole app from the 2026-11-25
/// Variant A mockup: a floating window (chrome bar + gesture legend) that
/// appears to sit in a physical room, rather than filling the screen.
///
/// [child] is the app's normal content (sidebar + body) - this only adds
/// the chrome above it and the gesture bar below it, inside one floating,
/// rounded, shadowed panel over [RoomPassthrough].
class SpatialShell extends StatelessWidget {
  final Widget child;
  const SpatialShell({super.key, required this.child});

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
                  child: Container(
                    color: AppColors.background,
                    child: Column(
                      children: [
                        const _WindowChrome(),
                        Expanded(child: child),
                        const _GestureBar(),
                        const _WindowGrabBar(),
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
        Positioned(
          top: -180,
          left: -160,
          child: _glow(const Color(0xFFFFD696), 240, 0.10),
        ),
        Positioned(
          top: -220,
          right: -180,
          child: _glow(AppColors.accent, 220, 0.09),
        ),
        Positioned(
          bottom: -240,
          left: 0,
          right: 0,
          child: Align(child: _glow(const Color(0xFF785A3C), 260, 0.16)),
        ),
      ],
    );
  }

  static Widget _glow(Color color, double radius, double opacity) {
    return IgnorePointer(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: radius,
              spreadRadius: radius * 0.3,
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowChrome extends StatelessWidget {
  const _WindowChrome();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    return Container(
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
    );
  }
}

class _WindowGrabBar extends StatelessWidget {
  const _WindowGrabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
