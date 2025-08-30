// lib/ui/widgets/drill_card.dart
import 'package:bowlsace/ui/widgets/shot_map_circles.dart';
import 'package:flutter/material.dart';

/// ---- Assumptions / Interfaces -----
/// Keep your existing domain models. These are just reference signatures:
/// class Drill { String id; String name; String description; int durationMinutes; List<SubDrill> subDrills; }
/// class SubDrill { String id; String title; String instruction; }
/// class Shot { int shotNumber; int mapLength; }
///
/// You already have ShotMapCircles in your project. We'll use it as-is.
/// import 'package:your_app/ui/widgets/shot_map_circles.dart';

typedef UpdateDrillDuration = void Function(String drillId, int newMinutes);
typedef RecordShot = void Function(String drillId, int mapLength, {String? subDrillId});
typedef UndoLastShot = void Function(String drillId);
typedef NotesChanged = void Function(String drillId, String notes);

class DrillCard extends StatelessWidget {
  const DrillCard({
    super.key,
    required this.drill,
    required this.shotsPerDrill,         // drillId -> List<Shot>
    required this.subDrillShotsCount,    // subDrillId -> int   (for display)
    required this.drillDurations,        // drillId -> int      (editable if no sub-drills)
    required this.subDrillDurations,     // subDrillId -> int   (for display)
    required this.currentMapLength,      // id -> selected value (0..ringCount)
    required this.notesPerDrill,         // drillId -> String
    required this.onUpdateDrillDuration,
    required this.onRecordShot,
    required this.onUndoLastShot,
    required this.onNotesChanged,
    this.ringCount = 4,
    this.ringColors = const [
      Color(0xFF91E0D6),
      Color(0xFFFFD37A),
      Color(0xFF9EC5FE),
      Color(0xFFF9A8D4),
    ],
    this.drillShotMapSize = 340,
    this.subDrillShotMapSize = 260,
    this.compactBreakpoint = 600,
  });

  final dynamic drill; // Use your Drill type
  final Map<String, List<dynamic>> shotsPerDrill;
  final Map<String, int> subDrillShotsCount;
  final Map<String, int> drillDurations;
  final Map<String, int> subDrillDurations;
  final Map<String, int> currentMapLength;
  final Map<String, String> notesPerDrill;

  final UpdateDrillDuration onUpdateDrillDuration;
  final RecordShot onRecordShot;
  final UndoLastShot onUndoLastShot;
  final NotesChanged onNotesChanged;

  final int ringCount;
  final List<Color> ringColors;
  final double drillShotMapSize;
  final double subDrillShotMapSize;
  final double compactBreakpoint;

  int _calculateDrillShots(dynamic drill) {
    if ((drill.subDrills as List).isEmpty) {
      return (shotsPerDrill[drill.id]?.length ?? 0);
    }
    int total = 0;
    for (final sd in (drill.subDrills as List)) {
      total += (subDrillShotsCount[sd.id] ?? 0);
    }
    return total;
  }

  int _calculateDrillDuration(dynamic drill) {
    if ((drill.subDrills as List).isEmpty) {
      return drillDurations[drill.id] ?? drill.durationMinutes;
    }
    int total = 0;
    for (final sd in (drill.subDrills as List)) {
      total += (subDrillDurations[sd.id] ?? 0);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < compactBreakpoint;
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    final drillShots = shotsPerDrill[drill.id] ?? const [];
    final totalShots = _calculateDrillShots(drill);
    final totalDuration = _calculateDrillDuration(drill);

    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 8 : 10,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TitleAndDesc(
                    title: drill.name,
                    description: drill.description,
                  ),
                ),
                if ((drill.subDrills as List).isNotEmpty)
                  _Badge(label: 'Has Sub-Drills', bg: color.primaryContainer, fg: color.onPrimaryContainer),
              ],
            ),

            SizedBox(height: isCompact ? 10 : 12),

            /// Metrics Grid (space-optimized)
            _MetricsGrid(
              items: [
                _MetricItem(
                  label: 'Total Shots',
                  value: '$totalShots',
                  icon: Icons.fiber_smart_record_outlined,
                ),
                _MetricItem(
                  label: 'Duration (min)',
                  value: '$totalDuration',
                  icon: Icons.timer_outlined,
                  trailing: (drill.subDrills as List).isEmpty
                      ? _DurationStepper(
                          value: drillDurations[drill.id] ?? drill.durationMinutes,
                          onInc: () => onUpdateDrillDuration(
                            drill.id,
                            (drillDurations[drill.id] ?? drill.durationMinutes) + 1,
                          ),
                          onDec: () => onUpdateDrillDuration(
                            drill.id,
                            (drillDurations[drill.id] ?? drill.durationMinutes) - 1,
                          ),
                        )
                      : null,
                ),
              ],
            ),

            SizedBox(height: isCompact ? 10 : 14),

            /// Shot Map (no sub-drills)
            if ((drill.subDrills as List).isEmpty) ...[
              _SectionHeader(
                title: 'Shot Map',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo),
                      tooltip: 'Undo last shot',
                      onPressed: () => onUndoLastShot(drill.id),
                    ),
                    _Badge(
                      label: '${drillShots.length} shots',
                      bg: color.primaryContainer,
                      fg: color.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Shot map + strip
              _Surface(
                child: Column(
                  children: [
                    ShotMapCircles(
                      selectedValue: currentMapLength[drill.id] ?? 0,
                      primaryColor: color.primary,
                      backgroundColor: color.outlineVariant,
                      size: isCompact ? drillShotMapSize - 50 : drillShotMapSize,
                      ringCount: ringCount,
                      ringColors: ringColors,
                      centerColor: color.primary,
                      onValueChanged: (v) => onRecordShot(drill.id, v),
                      showLegend: false,
                    ),
                    const SizedBox(height: 10),
                    _ShotsStrip(
                      shots: drillShots,
                      outline: color.outlineVariant,
                      primary: color.primary,
                    ),
                  ],
                ),
              ),
            ],

            /// Sub-Drills
            if ((drill.subDrills as List).isNotEmpty) ...[
              SizedBox(height: isCompact ? 10 : 12),
              const Divider(height: 24),
              _SectionHeader(
                title: 'Sub Drills',
                subtitle: 'Tap the shot map to record shots for each sub-drill',
                leadingIcon: Icons.layers_outlined,
              ),
              const SizedBox(height: 6),

              ...List.generate((drill.subDrills as List).length, (i) {
                final sd = drill.subDrills[i];
                final sdShots = subDrillShotsCount[sd.id] ?? 0;
                final sdDuration = subDrillDurations[sd.id] ?? 0;

                return Padding(
                  key: ValueKey(sd.id),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: color.primaryContainer,
                            child: Icon(Icons.sports_cricket, color: color.primary),
                          ),
                          title: Text(
                            sd.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color.primary,
                            ),
                          ),
                          subtitle: Text(sd.instruction ?? ''),
                          trailing: _MiniMetrics(
                            items: [
                              _MiniMetric(icon: Icons.fiber_smart_record_outlined, label: 'Shots', value: '$sdShots'),
                              _MiniMetric(icon: Icons.timer_outlined, label: 'Min', value: '$sdDuration'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: ShotMapCircles(
                            selectedValue: currentMapLength[sd.id] ?? 0,
                            primaryColor: color.secondary,
                            backgroundColor: color.secondaryContainer.withOpacity(0.3),
                            size: isCompact ? subDrillShotMapSize - 40 : subDrillShotMapSize,
                            ringCount: ringCount,
                            ringColors: ringColors,
                            centerColor: color.secondary,
                            onValueChanged: (v) => onRecordShot(drill.id, v, subDrillId: sd.id),
                            showLegend: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add notes for this drill...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                controller: TextEditingController(text: notesPerDrill[drill.id] ?? '')
                  ..selection = TextSelection.collapsed(offset: (notesPerDrill[drill.id] ?? '').length),
                onChanged: (v) => onNotesChanged(drill.id, v),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ----------------- Small UI Pieces -----------------

class _TitleAndDesc extends StatelessWidget {
  const _TitleAndDesc({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.25),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leadingIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 10.0, top: 2),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: color.primaryContainer,
              child: Icon(leadingIcon, color: color.primary, size: 18),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(subtitle!, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.items});
  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth > 420;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((e) {
            return SizedBox(
              width: twoCols && !isCompact ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth,
              child: _Surface(child: _MetricTile(item: e)),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricItem {
  _MetricItem({required this.label, required this.value, required this.icon, this.trailing});
  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item});
  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.primary.withOpacity(0.12),
            child: Icon(item.icon, color: color.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: theme.textTheme.labelMedium?.copyWith(color: color.onSurface.withOpacity(0.7))),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    item.value,
                    key: ValueKey(item.value),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item.trailing != null) item.trailing!,
        ],
      ),
    );
  }
}

class _DurationStepper extends StatelessWidget {
  const _DurationStepper({required this.value, required this.onInc, required this.onDec});
  final int value;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: onDec,
          tooltip: 'Decrease',
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.surfaceVariant,
          ),
          child: Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color.primary,
            ),
          ),
        ),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onInc,
          tooltip: 'Increase',
        ),
      ],
    );
  }
}

class _ShotsStrip extends StatelessWidget {
  const _ShotsStrip({
    required this.shots,
    required this.outline,
    required this.primary,
  });

  final List<dynamic> shots; // List<Shot>
  final Color outline;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    if (shots.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        reverse: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemBuilder: (context, index) {
          final shot = shots[index]; // with reverse: true, latest is first
          return _ShotPill(
            number: shot.shotNumber,
            mapLength: shot.mapLength,
            outline: outline,
            primary: primary,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: shots.length,
      ),
    );
  }
}

class _ShotPill extends StatelessWidget {
  const _ShotPill({
    required this.number,
    required this.mapLength,
    required this.outline,
    required this.primary,
  });

  final int number;
  final int mapLength;
  final Color outline;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fiber_smart_record_outlined, size: 18, color: primary),
          const SizedBox(height: 6),
          Text('#$number', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$mapLength',
              style: theme.textTheme.labelSmall?.copyWith(color: primary, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetrics extends StatelessWidget {
  const _MiniMetrics({required this.items});
  final List<_MiniMetric> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      list.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(it.icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text('${it.label}: ', style: theme.textTheme.labelSmall),
          Text(it.value, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ));
      if (i != items.length - 1) list.add(const SizedBox(width: 10));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: list);
  }
}

class _MiniMetric {
  _MiniMetric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
