import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'shots_wrap.dart';
import 'stat_widgets.dart';

class DrillTile extends StatelessWidget {
  final Map<String, dynamic> drill;
  const DrillTile({super.key, required this.drill});

  String _secs(int v) {
    final m = (v ~/ 60).toString().padLeft(2, '0');
    final s = (v % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    final name = (drill['name'] ?? 'Drill').toString();
    final shots = (drill['shots'] ?? 0) as int;
    final dur = (drill['duration_seconds'] ?? 0) as int;
    final acc = (drill['accuracy'] ?? 0).toString();
    final notes = (drill['notes'] ?? '').toString();

    final subDrills = (drill['sub_drills'] is List)
        ? drill['sub_drills'] as List
        : const [];
    final shotList = (drill['shot_list'] is List)
        ? drill['shot_list'] as List
        : const [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.14)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoBadge(icon: Icons.timer_outlined, text: _secs(dur)),
              InfoBadge(icon: Icons.burst_mode_outlined, text: '$shots shots'),
              InfoBadge(icon: Icons.timeline, text: '$acc% acc'),
              if (notes.isNotEmpty)
                const InfoBadge(icon: Icons.notes_outlined, text: 'Notes'),
            ],
          ),
          trailing: Icon(Icons.expand_more, color: c.onSurfaceVariant),
          children: [
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_outlined,
                    size: 18,
                    color: c.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: c.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Sub-drills
            if (subDrills.isNotEmpty) ...[
              Text(
                'Sub-drills',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...List.generate(
                subDrills.length,
                (i) => SubDrillTile(
                  sd: (subDrills[i] as Map<String, dynamic>? ?? {}),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Shots (at drill level)
            if (shotList.isNotEmpty) ...[
              Text(
                'Shots',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ShotsWrap(shots: shotList),
            ],
          ],
        ),
      ),
    );
  }
}

class SubDrillTile extends StatelessWidget {
  final Map<String, dynamic> sd;
  const SubDrillTile({super.key, required this.sd});

  String _secs(int v) {
    final m = (v ~/ 60).toString().padLeft(2, '0');
    final s = (v % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    final title = (sd['title'] ?? 'Sub-drill').toString();
    final shots = (sd['shots'] ?? 0) as int;
    final dur = (sd['duration_seconds'] ?? 0) as int;
    final shotList = (sd['shot_list'] is List)
        ? sd['shot_list'] as List
        : const [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surface.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoBadge(icon: Icons.timer_outlined, text: _secs(dur)),
              InfoBadge(icon: Icons.burst_mode_outlined, text: '$shots shots'),
            ],
          ),
          if (shotList.isNotEmpty) ...[
            const SizedBox(height: 8),
            ShotsWrap(shots: shotList),
          ],
        ],
      ),
    );
  }
}
