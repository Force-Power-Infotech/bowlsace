import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/drill_group_detail.dart';
import '../../../models/practice_session.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';

class GroupPracticeRecordingScreen extends StatefulWidget {
  final DrillGroupDetail drillGroup;

  const GroupPracticeRecordingScreen({Key? key, required this.drillGroup})
    : super(key: key);

  @override
  State<GroupPracticeRecordingScreen> createState() =>
      _GroupPracticeRecordingScreenState();
}

class _GroupPracticeRecordingScreenState
    extends State<GroupPracticeRecordingScreen> {
  int _currentDrillIndex = 0;
  Map<String, int> _shotsPerDrill = {};
  Map<String, double> _accuracyPerDrill = {};
  Map<String, String> _notesPerDrill = {};
  late PageController _pageController;

  // Sub-drill tracking maps
  Map<String, int> _subDrillShots = {};
  Map<String, int> _subDrillDurations = {};
  Map<String, int> _drillDurations = {}; // For storing drill durations

  // Time control variables
  late TextEditingController _timeController;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isPaused = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize maps for each drill
    int totalDuration = 0;
    for (var drill in widget.drillGroup.drills) {
      _shotsPerDrill[drill.id] = 0;
      _accuracyPerDrill[drill.id] = 0.0;
      _notesPerDrill[drill.id] = '';
      _drillDurations[drill.id] = drill.durationMinutes;

      // Initialize sub-drill maps
      for (var subDrill in drill.subDrills) {
        _subDrillShots[subDrill.id] = subDrill.numberOfShots ?? 0;
        _subDrillDurations[subDrill.id] =
            subDrill.duration ?? drill.durationMinutes;
      }

      // Add to total duration
      totalDuration += drill.subDrills.isEmpty
          ? drill.durationMinutes
          : drill.subDrills.fold(
              0,
              (sum, subDrill) => sum + (_subDrillDurations[subDrill.id] ?? 0),
            );
    }

    // Initialize timer with total duration
    _remainingSeconds = totalDuration * 60;
    _timeController = TextEditingController(text: '${totalDuration}:00');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0 && !_isPaused) {
          _remainingSeconds--;
        } else if (_remainingSeconds == 0) {
          _timer?.cancel();
          _isPaused = true;
          // Show completion dialog
          _showSessionCompleteDialog();
        }
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (!_isPaused) {
        _startTimer();
      }
    });
  }

  void _showTimeInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Practice Duration'),
        content: TextField(
          controller: _timeController,
          decoration: const InputDecoration(
            labelText: 'Duration (MM:SS)',
            hintText: '10:00',
          ),
          keyboardType: TextInputType.datetime,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parts = _timeController.text.split(':');
              if (parts.length == 2) {
                try {
                  final minutes = int.parse(parts[0]);
                  final seconds = int.parse(parts[1]);
                  if (minutes >= 0 && seconds >= 0 && seconds < 60) {
                    setState(() {
                      _remainingSeconds = (minutes * 60) + seconds;
                    });
                    Navigator.pop(context);
                    return;
                  }
                } catch (e) {
                  // Invalid format
                }
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter valid time (MM:SS)'),
                ),
              );
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Practice Session Complete'),
        content: const Text('Great job! Would you like to save this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Practice'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _savePracticeSession();
            },
            child: const Text('Save Session'),
          ),
        ],
      ),
    );
  }

  // Calculate total shots for a drill from its sub-drills
  int _calculateDrillShots(Drill drill) {
    if (drill.subDrills.isEmpty) {
      return _shotsPerDrill[drill.id] ?? 0;
    }
    return drill.subDrills.fold(
      0,
      (sum, subDrill) => sum + (_subDrillShots[subDrill.id] ?? 0),
    );
  }

  // Calculate total duration for a drill from its sub-drills
  int _calculateDrillDuration(Drill drill) {
    if (drill.subDrills.isEmpty) {
      return _drillDurations[drill.id] ?? drill.durationMinutes;
    }
    return drill.subDrills.fold(
      0,
      (sum, subDrill) => sum + (_subDrillDurations[subDrill.id] ?? 0),
    );
  }

  void _incrementShots(String drillId) {
    // Only allow incrementing shots if drill has no sub-drills
    final drill = widget.drillGroup.drills.firstWhere((d) => d.id == drillId);
    if (drill.subDrills.isEmpty) {
      setState(() {
        _shotsPerDrill[drillId] = (_shotsPerDrill[drillId] ?? 0) + 1;
      });
    }
  }

  void _decrementShots(String drillId) {
    // Only allow decrementing shots if drill has no sub-drills
    final drill = widget.drillGroup.drills.firstWhere((d) => d.id == drillId);
    if (drill.subDrills.isEmpty && (_shotsPerDrill[drillId] ?? 0) > 0) {
      setState(() {
        _shotsPerDrill[drillId] = (_shotsPerDrill[drillId] ?? 0) - 1;
      });
    }
  }

  void _updateSubDrillShots(String subDrillId, int shots) {
    setState(() {
      _subDrillShots[subDrillId] = shots.clamp(
        0,
        100,
      ); // Limit to reasonable range
    });
  }

  void _updateDrillDuration(String drillId, int duration) {
    setState(() {
      if (duration >= 0) {
        _drillDurations[drillId] = duration;
        _updateTotalTime();
      }
    });
  }

  void _updateSubDrillDuration(String subDrillId, int duration) {
    setState(() {
      if (duration >= 0) {
        _subDrillDurations[subDrillId] = duration;
        _updateTotalTime();
      }
    });
  }

  void _updateTotalTime() {
    int totalMinutes = 0;
    for (var drill in widget.drillGroup.drills) {
      totalMinutes += drill.subDrills.isEmpty
          ? (_drillDurations[drill.id] ?? drill.durationMinutes)
          : drill.subDrills.fold(
              0,
              (sum, subDrill) => sum + (_subDrillDurations[subDrill.id] ?? 0),
            );
    }
    _remainingSeconds = totalMinutes * 60;
    _timeController.text = '$totalMinutes:00';
  }

  Future<void> _savePracticeSession() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save practice session')),
      );
      return;
    }

    // Create a session for each drill
    final List<PracticeSession> sessions = [];
    for (var drill in widget.drillGroup.drills) {
      // Calculate total duration from sub-drills if they exist
      int totalDuration = drill.subDrills.isNotEmpty
          ? drill.subDrills.fold(
              0,
              (sum, subDrill) => sum + (_subDrillDurations[subDrill.id] ?? 0),
            )
          : (_drillDurations[drill.id] ?? drill.durationMinutes);

      // Calculate total shots from sub-drills if they exist
      int totalShots = drill.subDrills.isNotEmpty
          ? drill.subDrills.fold(
              0,
              (sum, subDrill) => sum + (_subDrillShots[subDrill.id] ?? 0),
            )
          : (_shotsPerDrill[drill.id] ?? 0);

      sessions.add(
        PracticeSession(
          id: '${DateTime.now().millisecondsSinceEpoch}_${drill.id}',
          drillGroupId: widget.drillGroup.id,
          drillId: drill.id,
          userId: user.id.toString(),
          duration: totalDuration,
          shots: totalShots,
          notes: _notesPerDrill[drill.id] ?? '',
          accuracy: _accuracyPerDrill[drill.id] ?? 0.0,
          createdAt: DateTime.now(),
        ),
      );
    }

    // TODO: Save sessions to backend
    Navigator.pop(context, sessions);
  }

  Widget _buildDrillCard(Drill drill) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Card(
      elevation: 8,
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drill.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              drill.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Total Shots section
                      Column(
                        children: [
                          Text(
                            'Total Shots',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.8),
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (drill.subDrills.isEmpty) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton.filled(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _decrementShots(drill.id),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    '${_shotsPerDrill[drill.id] ?? 0}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ),
                                IconButton.filled(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _incrementShots(drill.id),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              '${_calculateDrillShots(drill)}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                        ],
                      ),
                      // Total Duration section
                      Column(
                        children: [
                          Text(
                            'Duration (min)',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.8),
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (drill.subDrills.isEmpty) ...[
                            // Controls for drills without sub-drills
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _updateDrillDuration(
                                    drill.id,
                                    drill.durationMinutes - 1,
                                  ),
                                ),
                                Text(
                                  '${_drillDurations[drill.id] ?? drill.durationMinutes}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _updateDrillDuration(
                                    drill.id,
                                    drill.durationMinutes + 1,
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              '${_calculateDrillDuration(drill)}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Add notes for this drill...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                _notesPerDrill[drill.id] = value;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accuracy',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${((_accuracyPerDrill[drill.id] ?? 0) * 100).round()}%',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      thumbColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Slider(
                      value: _accuracyPerDrill[drill.id] ?? 0,
                      onChanged: (value) {
                        setState(() {
                          _accuracyPerDrill[drill.id] = value;
                        });
                      },
                      min: 0,
                      max: 1,
                      divisions: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (drill.subDrills.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Sub Drills',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...drill.subDrills.map(
                (subDrill) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(subDrill.title),
                          subtitle: Text(subDrill.instruction),
                          leading: const Icon(Icons.sports_cricket),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Shots',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed: () => _updateSubDrillShots(
                                            subDrill.id,
                                            (_subDrillShots[subDrill.id] ?? 0) -
                                                1,
                                          ),
                                        ),
                                        Text(
                                          '${_subDrillShots[subDrill.id] ?? 0}',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          onPressed: () => _updateSubDrillShots(
                                            subDrill.id,
                                            (_subDrillShots[subDrill.id] ?? 0) +
                                                1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Duration (min)',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed: () =>
                                              _updateSubDrillDuration(
                                                subDrill.id,
                                                (_subDrillDurations[subDrill
                                                            .id] ??
                                                        5) -
                                                    1,
                                              ),
                                        ),
                                        Text(
                                          '${_subDrillDurations[subDrill.id] ?? 5}',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          onPressed: () =>
                                              _updateSubDrillDuration(
                                                subDrill.id,
                                                (_subDrillDurations[subDrill
                                                            .id] ??
                                                        5) +
                                                    1,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.drillGroup.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: _showTimeInputDialog,
          ),
          IconButton(
            icon: Icon(_isPaused ? Icons.play_circle : Icons.pause_circle),
            onPressed: _togglePause,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: isSmallScreen ? 160 : 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(top: topPadding),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(_remainingSeconds),
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                        Text(
                          'Total Time',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.drillGroup.drills.length,
              onPageChanged: (index) {
                setState(() {
                  _currentDrillIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Drill ${index + 1}/${widget.drillGroup.drills.length}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            _buildDrillCard(widget.drillGroup.drills[index]),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentDrillIndex > 0)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                    ),
                  if (_currentDrillIndex > 0) const SizedBox(width: 8),
                  Expanded(
                    child:
                        _currentDrillIndex < widget.drillGroup.drills.length - 1
                        ? ElevatedButton.icon(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next'),
                          )
                        : ElevatedButton.icon(
                            onPressed: _savePracticeSession,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
