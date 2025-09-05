// lib/ui/widgets/common/ui_helpers.dart
// Reusable UI helpers (TimerChip, PageDots)

import 'package:flutter/material.dart';

/// A pill-shaped button that toggles between Pause ↔ Resume states.
///
/// By default it uses `colorScheme.primaryContainer` and the app's labelLarge
/// text style. You can override visuals via the optional parameters.
class TimerChip extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onTap;

  /// Optional customizations
  final String resumeLabel;
  final String pauseLabel;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final TextStyle? textStyle;

  const TimerChip({
    super.key,
    required this.isPaused,
    required this.onTap,
    this.resumeLabel = 'Resume',
    this.pauseLabel = 'Pause',
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.borderRadius = 999,
    this.iconSize = 18,
    this.backgroundColor,
    this.iconColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primaryContainer;
    final radius = Radius.circular(borderRadius);

    return Material(
      color: bg,
      borderRadius: BorderRadius.all(radius),
      child: InkWell(
        borderRadius: BorderRadius.all(radius),
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: iconSize,
                color: iconColor, // falls back to IconTheme if null
              ),
              const SizedBox(width: 6),
              Text(
                isPaused ? resumeLabel : pauseLabel,
                style: (textStyle ?? theme.textTheme.labelLarge)?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple page indicator dots with a wider active pill.
///
/// Tap a dot to jump (if [onDotTapped] is provided).
class PageDots extends StatelessWidget {
  final int count;
  final int index;
  final ValueChanged<int>? onDotTapped;

  /// Optional customizations
  final double dotHeight;
  final double dotWidth;
  final double activeWidth;
  final double spacing;
  final Duration animationDuration;
  final Color? activeColor;
  final Color? inactiveColor;

  const PageDots({
    super.key,
    required this.count,
    required this.index,
    this.onDotTapped,
    this.dotHeight = 8,
    this.dotWidth = 8,
    this.activeWidth = 20,
    this.spacing = 8,
    this.animationDuration = const Duration(milliseconds: 180),
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeC = activeColor ?? theme.colorScheme.primary;
    final inactiveC =
        inactiveColor ?? theme.colorScheme.outlineVariant.withOpacity(0.6);

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        final width = active ? activeWidth : dotWidth;

        final dot = AnimatedContainer(
          duration: animationDuration,
          height: dotHeight,
          width: width,
          decoration: BoxDecoration(
            color: active ? activeC : inactiveC,
            borderRadius: BorderRadius.circular(999),
          ),
        );

        if (onDotTapped == null) return dot;

        return GestureDetector(
          onTap: () => onDotTapped!(i),
          behavior: HitTestBehavior.opaque,
          child: dot,
        );
      }),
    );
  }
}
