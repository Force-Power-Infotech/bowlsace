import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int remainingSeconds;

  /// Optional: total session length in seconds (enables progress line)
  final int? totalSeconds;

  final bool isPaused;
  final VoidCallback onPauseToggle;
  final ValueChanged<int> onTimeChanged;
  final VoidCallback? onReset;

  const TimerAppBar({
    Key? key,
    required this.remainingSeconds,
    this.totalSeconds,
    required this.isPaused,
    required this.onPauseToggle,
    required this.onTimeChanged,
    this.onReset,
  }) : super(key: key);

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onPrimary = cs.onPrimary;
    final basePrimary = cs.primary;
    final baseContainer = cs.primaryContainer;

    // Progress 0..1 (if total provided)
    final progress = (totalSeconds == null || totalSeconds == 0)
        ? null
        : (1.0 - (remainingSeconds / totalSeconds!.clamp(1, 1 << 30))).clamp(
            0.0,
            1.0,
          );

    // Gentle “hurry up” pulse when < 10s
    final isHurry = remainingSeconds <= 10 && remainingSeconds >= 0;

    return AppBar(
      automaticallyImplyLeading: true,
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: kToolbarHeight + 20,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                basePrimary.withOpacity(0.95),
                baseContainer.withOpacity(0.90),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: basePrimary.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TIMER ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated big time
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1, end: isHurry ? 1.05 : 1.0),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    builder: (ctx, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Text(
                        _fmt(remainingSeconds),
                        key: ValueKey(remainingSeconds),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: onPrimary,
                              letterSpacing: 1.0,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Small “min:sec” pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'min:sec',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: onPrimary.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Edit time button
                  Tooltip(
                    message: 'Set time (MM:SS)',
                    child: InkWell(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await _showTimeSheet(context);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(Icons.edit, color: onPrimary),
                      ),
                    ),
                  ),
                ],
              ),

              // Progress line (if total provided)
              if (progress != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.isNaN ? 0 : progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isHurry ? Colors.redAccent.shade100 : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        // Pause / Play
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Tooltip(
            message: isPaused ? 'Resume' : 'Pause',
            child: _RoundIconButton(
              icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                onPauseToggle();
              },
            ),
          ),
        ),
        if (onReset != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: 'Reset timer',
              child: _RoundIconButton(
                icon: Icons.replay_rounded,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onReset!.call();
                },
              ),
            ),
          ),
      ],
      // Subtle curved bottom
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    );
  }

  Future<void> _showTimeSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : theme.colorScheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Set Total Time',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Done'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Quick presets
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in const [1, 2, 3, 5, 10, 15])
                      ActionChip(
                        label: Text('${m}m'),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onTimeChanged(m * 60);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // iOS-style picker
              SizedBox(
                height: 190,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.ms,
                  initialTimerDuration: Duration(seconds: remainingSeconds),
                  onTimerDurationChanged: (dur) {
                    onTimeChanged(dur.inSeconds.clamp(0, 24 * 60 * 60));
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 36);
}

/// Small rounded icon with soft shadow—great for AppBar actions.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({Key? key, required this.icon, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: cs.onSurface),
      ),
    );
  }
}
