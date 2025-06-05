import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/drill_group.dart';

class PracticeSessionScreen extends StatefulWidget {
  final DrillGroup drillGroup;

  const PracticeSessionScreen({super.key, required this.drillGroup});

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  final Map<int, bool> _selectedDrills = {};
  final Map<int, int> _drillDurations = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize all drills as unselected with their default durations
    for (final drill in widget.drillGroup.drills) {
      _selectedDrills[drill.id] = false;
      _drillDurations[drill.id] = drill.durationMinutes;
    }
  }

  void _toggleDrill(int drillId) {
    setState(() {
      _selectedDrills[drillId] = !(_selectedDrills[drillId] ?? false);
    });
  }

  void _updateDuration(int drillId, int duration) {
    setState(() {
      _drillDurations[drillId] = duration;
    });
  }

  Future<void> _submitSession() async {
    setState(() => _isSubmitting = true);
    try {
      // TODO: Implement session submission
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCount = _selectedDrills.values.where((v) => v).length;
    final totalDuration = _selectedDrills.entries
        .where((e) => e.value)
        .fold(0, (sum, e) => sum + (_drillDurations[e.key] ?? 0));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern sports-themed app bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Sports pattern background
                  CustomPaint(
                    painter: SportPatternPainter(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.8),
                          theme.primaryColorDark,
                        ],
                      ),
                    ),
                  ),
                  // Session info
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice Session',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.drillGroup.name,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Session summary
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    context,
                    Icons.sports_cricket,
                    '$selectedCount/${widget.drillGroup.drills.length}',
                    'Drills Selected',
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: theme.primaryColor.withOpacity(0.2),
                  ),
                  _buildSummaryItem(
                    context,
                    Icons.timer_outlined,
                    '$totalDuration min',
                    'Total Duration',
                  ),
                ],
              ),
            ),
          ),

          // Drill selection list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final drill = widget.drillGroup.drills[index];
                final isSelected = _selectedDrills[drill.id] ?? false;
                final duration =
                    _drillDurations[drill.id] ?? drill.durationMinutes;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isSelected
                        ? Border.all(color: theme.primaryColor, width: 2)
                        : null,
                  ),
                  child: InkWell(
                    onTap: () => _toggleDrill(drill.id),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Checkbox with sports theme
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.primaryColor
                                        : theme.dividerColor,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? theme.primaryColor
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 20,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      drill.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (drill.drillType != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        drill.drillType!.toUpperCase(),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 16),
                            // Duration slider
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Duration',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                    ),
                                    Text(
                                      '$duration minutes',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: theme.primaryColor,
                                    inactiveTrackColor: theme.primaryColor
                                        .withOpacity(0.2),
                                    thumbColor: theme.primaryColor,
                                    overlayColor: theme.primaryColor
                                        .withOpacity(0.1),
                                  ),
                                  child: Slider(
                                    value: duration.toDouble(),
                                    min: 5,
                                    max: 60,
                                    divisions: 11,
                                    onChanged: (value) => _updateDuration(
                                      drill.id,
                                      value.round(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Drill metrics
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[850]
                                    : theme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _buildDrillMetric(
                                    context,
                                    Icons.star_rounded,
                                    'Level ${drill.difficulty}',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildDrillMetric(
                                    context,
                                    Icons.track_changes,
                                    'Target: ${drill.targetScore}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: widget.drillGroup.drills.length),
            ),
          ),
        ],
      ),
      // Floating submit button
      floatingActionButton: AnimatedScale(
        scale: selectedCount > 0 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.extended(
          onPressed: selectedCount > 0 && !_isSubmitting
              ? _submitSession
              : null,
          backgroundColor: theme.primaryColor,
          elevation: 4,
          label: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'END SESSION ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.primaryColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.primaryColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDrillMetric(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class SportPatternPainter extends CustomPainter {
  final Color color;

  SportPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;
    const radius = 8.0;

    for (var x = -radius; x < size.width + radius; x += spacing) {
      for (var y = -radius; y < size.height + radius; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
