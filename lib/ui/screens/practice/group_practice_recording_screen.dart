import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../../models/drill_group_detail.dart';
import '../../../models/shot_record.dart';
import '../../../models/sub_drill.dart';
import '../../../repositories/user_repository.dart';
import '../../../api/services/practice_session_api.dart';

import '../../../di/service_locator.dart';
import '../../widgets/shot_map_circles.dart';

class GroupPracticeRecordingScreen extends StatefulWidget {
  final DrillGroupDetail drillGroup;

  final String sessionId;
  // Mapping of original drillId -> backend drill entry id
  final Map<String, String> drillEntryIdsByDrillId;

  const GroupPracticeRecordingScreen({
    Key? key,
    required this.drillGroup,
    required this.sessionId,
    required this.drillEntryIdsByDrillId,
  }) : super(key: key);

  @override
  State<GroupPracticeRecordingScreen> createState() =>
      _GroupPracticeRecordingScreenState();
}

class _GroupPracticeRecordingScreenState
    extends State<GroupPracticeRecordingScreen> {
  late final UserRepository _userRepository;
  late final PracticeSessionApi _practiceSessionApi;
  int _currentDrillIndex = 0;
  Map<String, List<ShotRecord>> _shotsPerDrill = {};
  Map<String, String> _notesPerDrill = {};
  Map<String, int> _currentMapLength = {};
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
    _userRepository = getIt<UserRepository>();
    _practiceSessionApi = getIt<PracticeSessionApi>();

    // Initialize maps for each drill
    int totalDuration = 0;
    for (var drill in widget.drillGroup.drills) {
      _shotsPerDrill[drill.id] = [];
      _notesPerDrill[drill.id] = '';
      _currentMapLength[drill.id] = 0;
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

  // Calculate total shots for a drill
  int _calculateDrillShots(Drill drill) {
    if (drill.subDrills.isEmpty) {
      return _shotsPerDrill[drill.id]?.length ?? 0;
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

  Future<void> _recordShot(
    String drillId,
    int mapLength, {
    String? subDrillId,
  }) async {
    try {
      // Resolve backend drill entry id from original drill id
      final drillEntryId = widget.drillEntryIdsByDrillId[drillId] ?? drillId;
      final nextShotNumber = subDrillId != null
          ? (_subDrillShots[subDrillId] ?? 0) + 1
          : (_shotsPerDrill[drillId]?.length ?? 0) + 1;

      if (kDebugMode) {
        debugPrint('⏳ Recording shot...');
        debugPrint(
          'Details:\n'
          '  Session ID: ${widget.sessionId}\n'
          '  Original Drill ID: $drillId\n'
          '  Backend Entry ID: $drillEntryId\n'
          '  Sub-drill ID: ${subDrillId ?? 'N/A'}\n'
          '  Map Length: $mapLength\n'
          '  Shot Number: $nextShotNumber\n'
          '  Current Shots Count: ${subDrillId != null ? _subDrillShots[subDrillId] : _shotsPerDrill[drillId]?.length ?? 0}\n'
          '  Has Entry ID Mapping: ${widget.drillEntryIdsByDrillId.containsKey(drillId)}',
        );
      }

      // Call the API to record the shot
      final result = await _practiceSessionApi.recordShot(
        sessionId: widget.sessionId,
        drillEntryId: drillEntryId,
        matLength: mapLength,
        shotNumber: nextShotNumber,
        subDrillId: subDrillId,
        useSubDrills: subDrillId != null,
      );

      if (kDebugMode) {
        debugPrint('✅ Shot recorded successfully');
        debugPrint('Response: $result');
      }

      // Update local state
      setState(() {
        if (subDrillId != null) {
          _subDrillShots[subDrillId] = nextShotNumber;
          _currentMapLength[subDrillId] = mapLength;
        } else {
          final shots = _shotsPerDrill[drillId] ?? [];
          shots.add(
            ShotRecord(
              shotNumber: shots.length + 1,
              mapLength: mapLength,
              timestamp: DateTime.now(),
            ),
          );
          _shotsPerDrill[drillId] = shots;
          _currentMapLength[drillId] = mapLength;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording shot: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _undoLastShot(String drillId) {
    if (!widget.drillGroup.drills.any(
      (d) => d.id == drillId && d.subDrills.isNotEmpty,
    )) {
      setState(() {
        final shots = _shotsPerDrill[drillId] ?? [];
        if (shots.isNotEmpty) {
          shots.removeLast();
          _shotsPerDrill[drillId] = shots;
          _currentMapLength[drillId] = shots.isEmpty ? 0 : shots.last.mapLength;
        }
      });
    }
  }

  void _updateSubDrillShots(
    String subDrillId,
    int shots, {
    int? mapLength,
  }) async {
    // Find the sub-drill and its parent drill
    String drillId = '';
    String drillName = '';
    String subDrillTitle = '';

    for (var drill in widget.drillGroup.drills) {
      final subDrill = drill.subDrills.firstWhere(
        (sd) => sd.id == subDrillId,
        orElse: () => SubDrill(
          title: '',
          instruction: '',
          drillId: '',
          id: '',
          createdAt: DateTime.now(),
        ),
      );
      if (subDrill.id == subDrillId) {
        drillId = drill.id;
        drillName = drill.name;
        subDrillTitle = subDrill.title;
        break;
      }
    }

    if (drillId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error: Could not find drill for this sub-drill'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      final newShots = shots.clamp(0, 100);

      // Resolve backend drill entry id from original drill id
      final drillEntryId = widget.drillEntryIdsByDrillId[drillId] ?? drillId;

      if (kDebugMode) {
        debugPrint(
          '[updateSubDrillShots] sessionId=${widget.sessionId} '
          'parentDrillId=$drillId entryId=$drillEntryId '
          'subDrillId=$subDrillId shots=$newShots',
        );
      }

      // Call the API to record the sub-drill shot
      await _practiceSessionApi.recordShot(
        sessionId: widget.sessionId,
        drillEntryId: drillEntryId,
        matLength: mapLength ?? 1, // Use provided map length or default
        shotNumber: newShots,
        subDrillId: subDrillId,
        useSubDrills: true,
      );

      setState(() {
        _subDrillShots[subDrillId] = newShots;
        if (drillName.isNotEmpty && subDrillTitle.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$drillName - $subDrillTitle: Shots updated to $newShots',
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating shots: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
    // Find the sub-drill and its parent drill
    String drillName = '';
    String subDrillTitle = '';
    for (var drill in widget.drillGroup.drills) {
      final subDrill = drill.subDrills.firstWhere(
        (sd) => sd.id == subDrillId,
        orElse: () => SubDrill(
          title: '',
          instruction: '',
          drillId: '',
          id: '',
          createdAt: DateTime.now(),
        ),
      );
      if (subDrill.id == subDrillId) {
        drillName = drill.name;
        subDrillTitle = subDrill.title;
        break;
      }
    }

    setState(() {
      if (duration >= 0) {
        _subDrillDurations[subDrillId] = duration;
        _updateTotalTime();
        if (drillName.isNotEmpty && subDrillTitle.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$drillName - $subDrillTitle: Duration updated to $duration min',
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int value,
    String? unit,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filled(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: onDecrease,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(32, 32),
                ),
              ),
              Text(
                unit != null ? '$value $unit' : '$value',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              IconButton.filled(
                icon: const Icon(Icons.add, size: 16),
                onPressed: onIncrease,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _savePracticeSession() async {
    try {
      // Get current user ID from user repository
      final user = await _userRepository.getCurrentUser();
      if (user == null) {
        throw Exception('User not found. Please login first.');
      }

      // Prepare sub-drills data for each drill
      final drills = widget.drillGroup.drills.map((drill) {
        // Get sub-drills data if they exist
        final subDrillsData = drill.subDrills
            .map(
              (subDrill) => {
                'id': subDrill.id,
                'name': subDrill.title,
                'duration': _subDrillDurations[subDrill.id] ?? 0,
                'shots': _subDrillShots[subDrill.id] ?? 0,
              },
            )
            .toList();

        // Calculate duration and shots
        final duration = drill.subDrills.isEmpty
            ? (_drillDurations[drill.id] ?? drill.durationMinutes)
            : subDrillsData.fold(0, (sum, sd) => sum + (sd['duration'] as int));

        // Calculate accuracy (defaulting to 100 as per API example)
        final accuracy = 100;

        return {
          'id': drill.id,
          'name': drill.name,
          'duration': duration,
          'shots': (_shotsPerDrill[drill.id]?.length ?? 0),
          'accuracy': accuracy,
          'notes': _notesPerDrill[drill.id] ?? '',
          'subDrills': subDrillsData,
        };
      }).toList();

      // Create the practice session (no idempotency key for now)
      final sessionResponse = await _practiceSessionApi.createPracticeSession(
        userId: user.id.toString(),
        drillGroupId: widget.drillGroup.id,
        drillGroupName: widget.drillGroup.name,
        totalDuration: _remainingSeconds ~/ 60,
        timestamp: DateTime.now(),
        drills: drills,
      );

      final String sessionId = sessionResponse['id'] as String;
      debugPrint('Practice session created with ID: $sessionId');

      // Build a map of original drillId -> drill entry id returned by session
      final Map<String, String> drillEntryIdsByDrillId = {};
      if (sessionResponse['drills'] is List) {
        for (final item in (sessionResponse['drills'] as List)) {
          if (item is Map<String, dynamic>) {
            final originalDrillId = item['drill_id'] as String?;
            final entryId = item['id'] as String?;
            if (originalDrillId != null && entryId != null) {
              drillEntryIdsByDrillId[originalDrillId] = entryId;
            }
          }
        }
      }

      // Now record individual shots for each drill
      for (var drill in widget.drillGroup.drills) {
        final shots = _shotsPerDrill[drill.id] ?? [];

        for (var shot in shots) {
          await _practiceSessionApi.recordShot(
            sessionId: sessionId,
            drillEntryId: drillEntryIdsByDrillId[drill.id] ?? drill.id,
            matLength: shot.mapLength,
            shotNumber: shot.shotNumber,
            useSubDrills: false,
          );
        }

        // If drill has sub-drills, record those shots too
        if (drill.subDrills.isNotEmpty) {
          for (var subDrill in drill.subDrills) {
            final numShots = _subDrillShots[subDrill.id] ?? 0;

            // For sub-drills, we just record the number of shots completed
            if (numShots > 0) {
              await _practiceSessionApi.recordShot(
                sessionId: sessionId,
                drillEntryId: drillEntryIdsByDrillId[drill.id] ?? drill.id,
                matLength: 1,
                shotNumber: numShots,
                subDrillId: subDrill.id,
                useSubDrills: true,
              );
            }
          }
        }
      }

      // Only proceed if context is still valid
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Practice session saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      // Only proceed if context is still valid
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving practice session: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                            Text(
                              '${_shotsPerDrill[drill.id]?.length ?? 0}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
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
                                    (_drillDurations[drill.id] ??
                                            drill.durationMinutes) -
                                        1,
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
                                    (_drillDurations[drill.id] ??
                                            drill.durationMinutes) +
                                        1,
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
                  if (kDebugMode) ...[
                    Builder(
                      builder: (context) {
                        final resolvedEntryId =
                            widget.drillEntryIdsByDrillId[drill.id] ?? drill.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.vpn_key_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Entry ID: $resolvedEntryId',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copy entry id',
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: resolvedEntryId),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Entry ID copied'),
                                        duration: Duration(milliseconds: 800),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  ShotMapCircles(
                    selectedValue: _currentMapLength[drill.id] ?? 0,
                    primaryColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant,
                    size: 360,
                    ringCount: 4,
                    // Optional: your own palette (index 0 -> value 1, etc.)
                    ringColors: const [
                      Color(0xFF91E0D6), // 1
                      Color(0xFFFFD37A), // 2
                      Color(0xFF9EC5FE), // 3
                      Color(0xFFF9A8D4), // 4
                    ],
                    centerColor: Theme.of(context).colorScheme.primary, // 0
                    onValueChanged: (v) => _recordShot(drill.id, v),
                    showLegend: false, // turn on if you want
                  ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shot Map',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.undo),
                            onPressed: () => _undoLastShot(drill.id),
                            tooltip: 'Undo last shot',
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_shotsPerDrill[drill.id]?.length ?? 0} shots',
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
                    ],
                  ),
                  // Header with actions

                  // Horizontal list
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final shots = _shotsPerDrill[drill.id] ?? [];
                        final shot = shots[shots.length - 1 - index];

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          width: 72,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fiber_smart_record_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '#${shot.shotNumber}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${shot.mapLength}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: _shotsPerDrill[drill.id]?.length ?? 0,
                    ),
                  ),
                ],
              ),
            ),
            if (drill.subDrills.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                title: Text(
                  'Sub Drills',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                subtitle: Text(
                  'Tap on the shot map to record shots for each sub-drill',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.layers_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...drill.subDrills.map((subDrill) {
                final shots = _subDrillShots[subDrill.id] ?? 0;
                final duration = _subDrillDurations[subDrill.id] ?? 0;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          subDrill.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        subtitle: Text(subDrill.instruction),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.sports_cricket,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shot map for sub-drill
                            ShotMapCircles(
                              selectedValue:
                                  _currentMapLength[subDrill.id] ?? 0,
                              primaryColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer.withOpacity(0.3),
                              size: 280,
                              ringCount: 4,
                              ringColors: const [
                                Color(0xFF91E0D6),
                                Color(0xFFFFD37A),
                                Color(0xFF9EC5FE),
                                Color(0xFFF9A8D4),
                              ],
                              centerColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              onValueChanged: (v) => _recordShot(
                                drill.id,
                                v,
                                subDrillId: subDrill.id,
                              ),
                              showLegend: false,
                            ),
                            const SizedBox(height: 16),
                            // Stats row with modern design
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            onPressed: () =>
                                                _updateSubDrillShots(
                                                  subDrill.id,
                                                  (_subDrillShots[subDrill
                                                              .id] ??
                                                          0) -
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
                                            onPressed: () =>
                                                _updateSubDrillShots(
                                                  subDrill.id,
                                                  (_subDrillShots[subDrill
                                                              .id] ??
                                                          0) +
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.only(
              top: topPadding,
              left: 16,
              right: 16,
              bottom: 12,
            ),
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
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // MM:SS (minutes:seconds) — bold, modern
                  Text(
                    '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Subtle label "min:sec"
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'min:sec',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Edit button -> minutes/seconds picker
                  IconButton(
                    tooltip: 'Set time (MM:SS)',
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () async {
                      // Bottom sheet with CupertinoTimerPicker in minutes/seconds mode
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (ctx) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(ctx).viewInsets.bottom,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  height: 4,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListTile(
                                  title: const Text('Set Total Time'),
                                  trailing: TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Done'),
                                  ),
                                ),
                                SizedBox(
                                  height: 180,
                                  child: CupertinoTimerPicker(
                                    mode: CupertinoTimerPickerMode
                                        .ms, // minutes & seconds
                                    initialTimerDuration: Duration(
                                      seconds: _remainingSeconds,
                                    ),
                                    onTimerDurationChanged: (dur) {
                                      setState(() {
                                        _remainingSeconds = dur.inSeconds;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          );
                        },
                      );
                    },
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
