import 'package:flutter/material.dart';
import '../../../models/drill_group_detail.dart';
import '../../../models/sub_drill.dart';
import 'drill_info_chip.dart';

class SubDrillCard extends StatelessWidget {
  final SubDrill subDrill;

  const SubDrillCard({Key? key, required this.subDrill}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subDrill.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subDrill.numberOfShots != null)
                      DrillInfoChip(
                        icon: Icons.sports_cricket,
                        label: '${subDrill.numberOfShots} shots',
                        containerColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        textColor: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                      ),
                    if (subDrill.duration != null) ...[
                      if (subDrill.numberOfShots != null)
                        const SizedBox(width: 8),
                      DrillInfoChip(
                        icon: Icons.timer_outlined,
                        label: '${subDrill.duration} min',
                        containerColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        textColor: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subDrill.instruction,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
