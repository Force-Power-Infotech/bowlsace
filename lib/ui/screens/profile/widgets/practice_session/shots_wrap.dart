import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'stat_widgets.dart';

class ShotsWrap extends StatelessWidget {
  final List shots;
  const ShotsWrap({super.key, required this.shots});

  String _fmtTs(dynamic s) {
    if (s == null) return '';
    final dt = DateTime.tryParse(s.toString());
    if (dt == null) return '';
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(shots.length, (i) {
        final shot = (shots[i] as Map<String, dynamic>? ?? {});
        final num = (shot['shot_number'] ?? i + 1).toString();
        final mat = (shot['mat_length'] ?? '').toString();
        final ts = _fmtTs(shot['created_at']);
        final subtitle = [
          if (mat.isNotEmpty) 'Mat $mat',
          if (ts.isNotEmpty) ts,
        ].join(' • ');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: c.primaryContainer.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shot $num',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
