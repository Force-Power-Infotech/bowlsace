import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/drill_group.dart';
import '../../../models/drill.dart';
import '../../../providers/practice_provider.dart';
import '../../../providers/user_provider.dart';

class PracticeSessionScreen extends StatefulWidget {
  final DrillGroup? drillGroup;
  final Drill? drill;

  const PracticeSessionScreen({
    super.key,
    this.drillGroup,
    this.drill,
  }) : assert(drillGroup != null || drill != null);

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  final Map<int, bool> _selectedDrills = {};
  final Map<int, int> _drillDurations = {};
  bool _isSubmitting = false;
  String? _sessionName;
  String? _location;

  @override
  void initState() {
    super.initState();
    if (widget.drillGroup != null) {
      // Initialize all drills as unselected with their default durations
      for (final drill in widget.drillGroup!.drills) {
        _selectedDrills[drill.id] = false;
        _drillDurations[drill.id] = drill.durationMinutes;
      }
      _sessionName = '${widget.drillGroup!.name} Practice';
    } else if (widget.drill != null) {
      // Initialize single drill as selected
      _selectedDrills[widget.drill!.id] = true;
      _drillDurations[widget.drill!.id] = widget.drill!.durationMinutes;
      _sessionName = '${widget.drill!.name} Practice';
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

  void _updateSessionName(String name) {
    setState(() {
      _sessionName = name;
    });
  }

  void _updateLocation(String location) {
    setState(() {
      _location = location;
    });
  }

  Future<void> _submitSession() async {
    if (!mounted) return;

    final provider = Provider.of<PracticeProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to start a practice session'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get selected drill IDs
      final selectedDrillIds = widget.drillGroup?.drills
              .where((d) => _selectedDrills[d.id] ?? false)
              .map((d) => d.id)
              .toList() ??
          [widget.drill!.id];

      // Create practice sessions
      final sessions = await provider.createPracticeSessions(
        drillGroupId: widget.drillGroup?.id ?? widget.drill!.id,
        drillIds: selectedDrillIds,
        userId: userProvider.user!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created ${sessions.length} practice sessions'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create practice sessions: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
    final drills = widget.drillGroup?.drills ?? [widget.drill!];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.drillGroup != null ? 'New Practice Session' : 'Start Drill'),
        elevation: 0,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Session name input
                        TextField(
                          controller: TextEditingController(text: _sessionName),
                          onChanged: _updateSessionName,
                          decoration: InputDecoration(
                            labelText: 'Session Name',
                            hintText: 'Enter a name for your practice session',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.edit),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Location input
                        TextField(
                          controller: TextEditingController(text: _location),
                          onChanged: _updateLocation,
                          decoration: InputDecoration(
                            labelText: 'Location (Optional)',
                            hintText: 'Enter practice location',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Practice duration summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Duration',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${_drillDurations.entries.where((e) => _selectedDrills[e.key] ?? false).fold<int>(0, (sum, e) => sum + e.value)} minutes',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (widget.drillGroup != null) ...[
                          Text(
                            'Select Drills',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                // Drill list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final drill = drills[index];
                        final isSelected = _selectedDrills[drill.id] ?? false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: widget.drillGroup != null
                                ? () => _toggleDrill(drill.id)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  if (widget.drillGroup != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (_) => _toggleDrill(drill.id),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          drill.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (drill.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            drill.description,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme
                                                  .textTheme.bodySmall?.color,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        // Duration slider
                                        if (isSelected) ...[
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.timer_outlined,
                                                size: 16,
                                                color: theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Slider(
                                                  value: _drillDurations[
                                                          drill.id]!
                                                      .toDouble(),
                                                  min: 5,
                                                  max: 60,
                                                  divisions: 11,
                                                  label:
                                                      '${_drillDurations[drill.id]} min',
                                                  onChanged: (value) =>
                                                      _updateDuration(
                                                    drill.id,
                                                    value.round(),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 50,
                                                child: Text(
                                                  '${_drillDurations[drill.id]} min',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: drills.length,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _selectedDrills.values.any((selected) => selected)
                ? _submitSession
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Start Practice'),
          ),
        ),
      ),
    );
  }
}
