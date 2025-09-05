import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'drill_tiles.dart';
import 'stat_widgets.dart';

class PracticeSessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  const PracticeSessionCard({super.key, required this.session});

  String _formatDateTime(dynamic dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    final parsed = DateTime.tryParse(dateTimeStr.toString());
    if (parsed == null) return 'N/A';
    return DateFormat('MMM d, y • h:mm a').format(parsed.toLocal());
  }

  String _secsToClock(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    final groupName =
        (session['drill_group_name'] as String?) ?? 'Untitled Session';
    final totalShots = (session['total_shots'] ?? 0) as int;
    final durationSecs = (session['total_duration_seconds'] ?? 0) as int;
    final avgAcc = (session['avg_accuracy'] ?? 0).toString();
    final startedAt = session['started_at'];
    final drills = (session['drills'] is List)
        ? (session['drills'] as List)
        : const [];

    final shotsFromDrills = drills.fold<int>(
      0,
      (acc, d) => acc + (((d as Map?)?['shots'] ?? 0) as int),
    );
    final totalShotsSafe = (totalShots == 0 && shotsFromDrills > 0)
        ? shotsFromDrills
        : totalShots;

    final durationFromDrills = drills.fold<int>(
      0,
      (acc, d) => acc + ((d as Map?)?['duration_seconds'] ?? 0) as int,
    );
    final totalDurationSafe = (durationSecs == 0 && durationFromDrills > 0)
        ? durationFromDrills
        : durationSecs;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (Title + shots)
            Row(
              children: [
                Expanded(
                  child: Text(
                    groupName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "$totalShotsSafe shots",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: c.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Compact Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  icon: Icons.timer_outlined,
                  label: _secsToClock(totalDurationSafe),
                ),
                _MiniStat(icon: Icons.timeline, label: '$avgAcc%'),
                _MiniStat(icon: Icons.sports, label: '${drills.length} drills'),
              ],
            ),

            const SizedBox(height: 8),
            Divider(color: Colors.grey.withOpacity(0.15), height: 20),

            // Drills compact list
            if (drills.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drills:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...drills
                      .take(2)
                      .map((d) => DrillTile(drill: d as Map<String, dynamic>)),
                  if (drills.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+${drills.length - 2} more',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              )
            else
              Text(
                'No drills recorded',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
              ),

            const SizedBox(height: 6),

            // Footer row
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: c.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatDateTime(startedAt),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: c.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: c.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: c.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
