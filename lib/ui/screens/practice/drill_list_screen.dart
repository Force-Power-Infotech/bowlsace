import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/drill.dart';
import '../../../models/drill_group.dart';
import '../../../providers/practice_provider.dart';
import 'create_practice_screen.dart';

class DrillListScreen extends StatelessWidget {
  final DrillGroup drillGroup;

  const DrillListScreen({super.key, required this.drillGroup});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header with group image and details
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Group Image with gradient overlay
                  Image.network(drillGroup.imageUrl, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Group details overlay
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drillGroup.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            drillGroup.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Stats row
                          Row(
                            children: [
                              _buildStat(
                                context,
                                Icons.sports,
                                '${drillGroup.drills.length} Drills',
                              ),
                              const SizedBox(width: 24),
                              _buildStat(
                                context,
                                Icons.timer,
                                '${drillGroup.totalDuration} mins',
                              ),
                              const SizedBox(width: 24),
                              _buildStat(
                                context,
                                Icons.star,
                                drillGroup.difficulty.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tags list
          if (drillGroup.tags.isNotEmpty)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: drillGroup.tags.map((tag) {
                    return Container(
                      margin: const EdgeInsets.only(left: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: drillGroup.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: drillGroup.accentColor.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: drillGroup.accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Drills list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final drill = drillGroup.drills[index];
                return _DrillCard(
                  drill: drill,
                  drillGroup: drillGroup,
                  index: index,
                );
              }, childCount: drillGroup.drills.length),
            ),
          ),
        ],
      ),
      // Start Practice FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreatePracticeScreen(drillGroup: drillGroup),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Practice'),
        backgroundColor: drillGroup.accentColor,
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
      ],
    );
  }
}

class _DrillCard extends StatelessWidget {
  final Drill drill;
  final DrillGroup drillGroup;
  final int index;

  const _DrillCard({
    required this.drill,
    required this.drillGroup,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 2,
        child: InkWell(
          onTap: () {
            // Select this drill and navigate to practice screen
            Provider.of<PracticeProvider>(
              context,
              listen: false,
            ).setSelectedDrill(drill);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CreatePracticeScreen(drillGroup: drillGroup),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Drill number indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: drillGroup.accentColor.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: drillGroup.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Drill details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drill.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDrillTag(
                            Icons.timer,
                            '${drill.durationMinutes} mins',
                          ),
                          const SizedBox(width: 16),
                          _buildDrillTag(
                            Icons.fitness_center,
                            drill.difficulty.toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Play button
                Icon(
                  Icons.play_circle_fill,
                  color: drillGroup.accentColor,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrillTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
