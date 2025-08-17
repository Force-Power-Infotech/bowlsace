import 'package:flutter/material.dart';
import '../../../models/drill_group_detail.dart';
import 'drill_info_chip.dart';
import 'sub_drill_card.dart';

class DrillCard extends StatefulWidget {
  final Drill drill;

  const DrillCard({Key? key, required this.drill}) : super(key: key);

  @override
  State<DrillCard> createState() => _DrillCardState();
}

class _DrillCardState extends State<DrillCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
          if (!_isExpanded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected: ${widget.drill.name}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.drill.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  widget.drill.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                      child: const Center(
                        child: Icon(Icons.sports_cricket, size: 64),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.drill.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DrillStatusChip(isActive: widget.drill.isActive),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.drill.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDrillInfoChips(context),
                  if (widget.drill.videoUrl != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Handle video playback
                      },
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Watch Video'),
                    ),
                  ],
                  if (_isExpanded && widget.drill.subDrills.isNotEmpty)
                    _buildSubDrillsSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrillInfoChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        DrillInfoChip(
          icon: Icons.timer,
          label: '${widget.drill.durationMinutes} min',
          containerColor: Theme.of(context).colorScheme.primaryContainer,
          textColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        DrillInfoChip(
          icon: Icons.star,
          label: 'Difficulty: ${widget.drill.difficulty}',
          containerColor: Theme.of(context).colorScheme.secondaryContainer,
          textColor: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        if (widget.drill.drillType.isNotEmpty)
          DrillInfoChip(
            label: widget.drill.drillType,
            containerColor: Theme.of(context).colorScheme.tertiaryContainer,
            textColor: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        if (widget.drill.numberOfShots != null)
          DrillInfoChip(
            icon: Icons.sports_cricket,
            label: '${widget.drill.numberOfShots} shots',
            containerColor: Theme.of(context).colorScheme.surfaceVariant,
            textColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }

  Widget _buildSubDrillsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Row(
          children: [
            Text(
              'Sub-drills',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.drill.subDrills.length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.drill.subDrills.length,
          itemBuilder: (context, index) {
            return SubDrillCard(subDrill: widget.drill.subDrills[index]);
          },
        ),
      ],
    );
  }
}
