import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/sub_drill.dart';
import 'drill_info_chip.dart';

class SubDrillCard extends StatefulWidget {
  final SubDrill subDrill;

  const SubDrillCard({Key? key, required this.subDrill}) : super(key: key);

  @override
  State<SubDrillCard> createState() => _SubDrillCardState();
}

class _SubDrillCardState extends State<SubDrillCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurfaceSubtle = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.75);

    final hasShots = widget.subDrill.numberOfShots != null;
    final hasDuration = widget.subDrill.duration != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          scale: _pressed ? 0.98 : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Subtle gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primaryContainer.withOpacity(0.14),
                        cs.secondaryContainer.withOpacity(0.10),
                      ],
                    ),
                  ),
                ),
                // Glass blur & border
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _CardContent(
                      subDrill: widget.subDrill,
                      onSurfaceSubtle: onSurfaceSubtle,
                      cs: cs,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final SubDrill subDrill;
  final Color onSurfaceSubtle;
  final ColorScheme cs;

  const _CardContent({
    required this.subDrill,
    required this.onSurfaceSubtle,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + title + chips
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact sport icon badge
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withOpacity(0.22)),
                ),
                child: Icon(Icons.sports_cricket, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 12),
              // Title + chips (wrap for responsiveness)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      subDrill.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (subDrill.numberOfShots != null)
                          DrillInfoChip(
                            icon: Icons.sports_baseball_outlined,
                            label: '${subDrill.numberOfShots} shots',
                            containerColor: cs.primaryContainer,
                            textColor: cs.onPrimaryContainer,
                          ),
                        if (subDrill.duration != null)
                          DrillInfoChip(
                            icon: Icons.timer_outlined,
                            label: '${subDrill.duration} min',
                            containerColor: cs.secondaryContainer,
                            textColor: cs.onSecondaryContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Divider (soft, inset)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  cs.outlineVariant.withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Instruction
          Text(
            subDrill.instruction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: onSurfaceSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
