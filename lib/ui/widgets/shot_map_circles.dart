import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShotMapCircles extends StatefulWidget {
  final double size;
  final int selectedValue; // 0..ringCount
  final Color primaryColor;
  final Color backgroundColor;
  final ValueChanged<int> onValueChanged;
  final bool isEnabled;
  final int ringCount; // values 1..ringCount (+ center 0)
  final List<Color>?
  ringColors; // length >= ringCount (colors for 1..ringCount)
  final Color? centerColor; // color for 0
  final bool showLegend; // keep UI uncluttered by default

  const ShotMapCircles({
    Key? key,
    required this.selectedValue,
    this.size = 240,
    required this.primaryColor,
    required this.backgroundColor,
    required this.onValueChanged,
    this.isEnabled = true,
    this.ringCount = 4,
    this.ringColors,
    this.centerColor,
    this.showLegend = false,
  }) : super(key: key);

  @override
  State<ShotMapCircles> createState() => _ShotMapCirclesState();
}

class _ShotMapCirclesState extends State<ShotMapCircles>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  // Pleasant, readable default palette (pastel rings)
  List<Color> get _defaultRingColors => [
    const Color(0xFF9AD0C2), // 1 mint
    const Color(0xFFF6BD60), // 2 amber
    const Color(0xFFA7C7E7), // 3 baby blue
    const Color(0xFFF5A3C7), // 4 pink
    const Color(0xFFB7E4C7), // 5 (if needed)
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _select(int value) {
    if (!widget.isEnabled) return;
    HapticFeedback.lightImpact();
    widget.onValueChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size.clamp(200.0, 520.0);
    final primary = widget.primaryColor;
    final bg = widget.backgroundColor;

    final ringColors = (widget.ringColors ?? _defaultRingColors);
    // Ensure we have enough colors
    final safeRingColors = List<Color>.generate(
      widget.ringCount,
      (i) => i < ringColors.length ? ringColors[i] : ringColors.last,
    );
    final centerColor = widget.centerColor ?? primary;

    return Semantics(
      label: 'Shot map selector',
      hint: 'Tap a circle to set mat length from 0 to ${widget.ringCount}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live selection chip
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: widget.selectedValue == 0
                      ? primary
                      : primary.withOpacity(0.55),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: widget.selectedValue == 0
                        ? primary
                        : primary.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mat Length: ${widget.selectedValue}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // soft background plate
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),

                // Rings (largest -> smallest)
                for (int i = widget.ringCount - 1; i >= 0; i--)
                  _RingButton(
                    index: i,
                    size: size,
                    labelValue: i + 1,
                    ringColor: safeRingColors[i],
                    borderColor: widget.selectedValue == i + 1
                        ? safeRingColors[i].withOpacity(0.95)
                        : bg.withOpacity(0.7),
                    textColor: widget.selectedValue == i + 1
                        ? safeRingColors[i].withOpacity(0.95)
                        : Colors.black.withOpacity(0.65),
                    isSelected: widget.selectedValue == i + 1,
                    isEnabled: widget.isEnabled,
                    pulse: _pulse,
                    onTap: () => _select(i + 1),
                  ),

                // Center 0 (solid color plate so text never overlaps visually)
                _CenterDot(
                  size: size,
                  isSelected: widget.selectedValue == 0,
                  fillColor: widget.selectedValue == 0
                      ? centerColor
                      : bg.withOpacity(0.14),
                  borderColor: widget.selectedValue == 0
                      ? centerColor
                      : bg.withOpacity(0.7),
                  textColor: widget.selectedValue == 0
                      ? Colors.white
                      : bg, // readable
                  isEnabled: widget.isEnabled,
                  pulse: _pulse,
                  onTap: () => _select(0),
                ),

                if (widget.showLegend)
                  Positioned(
                    right: 0,
                    child: _Legend(
                      count: widget.ringCount,
                      selected: widget.selectedValue,
                      primary: primary,
                      bg: bg,
                      ringColors: safeRingColors,
                      onTap: (v) => _select(v),
                      isEnabled: widget.isEnabled,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Tap the ring that matches where your bowl stopped',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingButton extends StatelessWidget {
  final int index; // 0..(ringCount-1)
  final double size;
  final int labelValue; // 1..ringCount
  final Color ringColor;
  final Color borderColor;
  final Color textColor;
  final bool isSelected;
  final bool isEnabled;
  final AnimationController pulse;
  final VoidCallback onTap;

  const _RingButton({
    required this.index,
    required this.size,
    required this.labelValue,
    required this.ringColor,
    required this.borderColor,
    required this.textColor,
    required this.isSelected,
    required this.isEnabled,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Slightly larger base to prevent crowding, but still airy
    final circleSize = size * (0.43 + (index * 0.145));

    return IgnorePointer(
      ignoring: !isEnabled,
      child: Semantics(
        button: true,
        label: 'Select mat length $labelValue',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ringColor.withOpacity(isSelected ? 0.18 : 0.10),
            border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ringColor.withOpacity(0.28),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkResponse(
              onTap: onTap,
              radius: circleSize / 2,
              highlightShape: BoxShape.circle,
              containedInkWell: true,
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  scale: isSelected ? 1.07 : 1.0,
                  child: AnimatedBuilder(
                    animation: pulse,
                    builder: (_, __) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Gentle pulse halo only when selected
                          if (isSelected)
                            Container(
                              width: circleSize * (0.62 + pulse.value * 0.06),
                              height: circleSize * (0.62 + pulse.value * 0.06),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ringColor.withOpacity(0.08),
                              ),
                            ),
                          // Number
                          Text(
                            '$labelValue',
                            style: TextStyle(
                              color: textColor,
                              fontSize: (size * 0.085).clamp(14, 24),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterDot extends StatelessWidget {
  final double size;
  final bool isSelected;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final bool isEnabled;
  final AnimationController pulse;
  final VoidCallback onTap;

  const _CenterDot({
    required this.size,
    required this.isSelected,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.isEnabled,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.18; // a touch larger for readability

    return IgnorePointer(
      ignoring: !isEnabled,
      child: Semantics(
        button: true,
        label: 'Select mat length 0',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                fillColor, // solid plate ensures number never blends/overlaps
            border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: fillColor.withOpacity(0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkResponse(
              onTap: onTap,
              radius: dot,
              highlightShape: BoxShape.circle,
              containedInkWell: true,
              child: AnimatedBuilder(
                animation: pulse,
                builder: (_, __) {
                  // keep halo very subtle so it doesn't “cover” text
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isSelected)
                        Container(
                          width: dot * (1.18 + pulse.value * 0.06),
                          height: dot * (1.18 + pulse.value * 0.06),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: fillColor.withOpacity(0.08),
                          ),
                        ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '0',
                          maxLines: 1,
                          style: TextStyle(
                            color: textColor,
                            fontSize: (size * 0.09).clamp(14, 24),
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final int count;
  final int selected;
  final Color primary;
  final Color bg;
  final List<Color> ringColors;
  final bool isEnabled;
  final ValueChanged<int> onTap;

  const _Legend({
    required this.count,
    required this.selected,
    required this.primary,
    required this.bg,
    required this.ringColors,
    required this.onTap,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          _legendItem(0, Colors.grey.shade600),
          for (int v = 1; v <= count; v++) _legendItem(v, ringColors[v - 1]),
        ],
      ),
    );
  }

  Widget _legendItem(int v, Color color) {
    final isSel = v == selected;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: isEnabled ? () => onTap(v) : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: isSel ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? color.withOpacity(0.9) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSel
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 16,
                color: isSel ? color.withOpacity(0.95) : bg.withOpacity(0.9),
              ),
              const SizedBox(width: 6),
              Text(
                '$v',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSel ? color.withOpacity(0.95) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
