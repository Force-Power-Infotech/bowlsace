import 'dart:async';
import 'dart:convert';

import 'package:bowlsace/ui/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../models/drill_group_detail.dart';
import '../../../models/shot_record.dart';
import '../../../models/sub_drill.dart';
import '../../../repositories/user_repository.dart';
import '../../../api/services/practice_session_api.dart';
import '../../../api/api_client.dart';

import '../../../di/service_locator.dart';
import '../../widgets/drill_card.dart';

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

  // Paging / progress
  late final PageController _pageController;
  int _currentDrillIndex = 0;

  // Drill + subdrill state
  final Map<String, List<ShotRecord>> _shotsPerDrill = {};
  final Map<String, String> _notesPerDrill = {};
  final Map<String, int> _currentMapLength = {};
  final Map<String, int> _subDrillShots = {};
  final Map<String, int> _subDrillDurations = {};
  final Map<String, int> _drillDurations = {};

  // Time control
  late final TextEditingController _timeController;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isPaused = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _userRepository = getIt<UserRepository>();
    _practiceSessionApi = getIt<PracticeSessionApi>();

    // Initialize maps for each drill and compute total duration
    int totalDuration = 0;
    for (var drill in widget.drillGroup.drills) {
      _shotsPerDrill[drill.id] = [];
      _notesPerDrill[drill.id] = '';
      _currentMapLength[drill.id] = 0;
      _drillDurations[drill.id] = drill.durationMinutes;

      for (var subDrill in drill.subDrills) {
        _subDrillShots[subDrill.id] = subDrill.numberOfShots ?? 0;
        _subDrillDurations[subDrill.id] =
            subDrill.duration ?? drill.durationMinutes;
      }

      totalDuration += drill.subDrills.isEmpty
          ? drill.durationMinutes
          : drill.subDrills.fold(
              0,
              (sum, s) => sum + (_subDrillDurations[s.id] ?? 0),
            );
    }

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

  // ---------- Timer ----------
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0 && !_isPaused) {
          _remainingSeconds--;
        } else if (_remainingSeconds == 0) {
          _timer?.cancel();
          _isPaused = true;
          _showSessionCompleteDialog();
        }
      });
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (!_isPaused) _startTimer();
    });
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

  // ---------- Logging helpers ----------
  void _logJson(Map<String, dynamic> data) {
    if (kDebugMode) {
      try {
        debugPrint(jsonEncode(data));
      } catch (_) {
        debugPrint(
          jsonEncode({
            'level': 'warn',
            'event': 'log.encode_fallback',
            'payload_as_string': data.toString(),
          }),
        );
      }
    }
  }

  Map<String, dynamic> _resultToJson(dynamic result) {
    if (result is Map<String, dynamic> || result is List)
      return {'data': result};
    return {'data': result?.toString()};
  }

  Map<String, dynamic> _errToJson(Object error, [StackTrace? st]) {
    final map = <String, dynamic>{
      'type': error.runtimeType.toString(),
      'toString': error.toString(),
    };
    try {
      final msg = (error as dynamic).message;
      if (msg != null) map['message'] = msg;
    } catch (_) {}
    try {
      final code = (error as dynamic).statusCode;
      if (code != null) map['statusCode'] = code;
    } catch (_) {}
    try {
      final body = (error as dynamic).body;
      if (body != null) map['body'] = body;
    } catch (_) {}
    if (st != null) map['stack'] = st.toString();
    return map;
  }

  // ---------- Shot actions ----------
  Future<void> _recordShot(
    String drillId,
    int mapLength, {
    String? subDrillId,
  }) async {
    const int maxAttempts = 3;
    const Duration baseDelay = Duration(milliseconds: 800);
    NetworkException? lastNetErr;

    final drillEntryId = widget.drillEntryIdsByDrillId[drillId] ?? drillId;
    final nextShotNumber = subDrillId != null
        ? (_subDrillShots[subDrillId] ?? 0) + 1
        : (_shotsPerDrill[drillId]?.length ?? 0) + 1;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _logJson({
          'level': 'info',
          'event': 'recordShot.attempt',
          'attempt': attempt,
          'maxAttempts': maxAttempts,
          'request': {
            'sessionId': widget.sessionId,
            'originalDrillId': drillId,
            'backendEntryId': drillEntryId,
            'subDrillId': subDrillId,
            'mapLength': mapLength,
            'shotNumber': nextShotNumber,
            'currentShotsCount': subDrillId != null
                ? (_subDrillShots[subDrillId] ?? 0)
                : (_shotsPerDrill[drillId]?.length ?? 0),
            'hasEntryIdMapping': widget.drillEntryIdsByDrillId.containsKey(
              drillId,
            ),
          },
        });

        final result = await _practiceSessionApi.recordShot(
          sessionId: widget.sessionId,
          drillEntryId: drillEntryId,
          matLength: mapLength,
          shotNumber: nextShotNumber,
          subDrillId: subDrillId,
          useSubDrills: subDrillId != null,
        );

        _logJson({
          'level': 'info',
          'event': 'recordShot.success',
          'attempt': attempt,
          ..._resultToJson(result),
        });

        if (!mounted) return;
        setState(() {
          if (subDrillId != null) {
            _subDrillShots[subDrillId] = nextShotNumber;
            _currentMapLength[subDrillId] = mapLength;
          } else {
            final shots = _shotsPerDrill[drillId] ?? [];
            shots.add(
              ShotRecord(
                mapLength: mapLength,
                shotNumber: nextShotNumber,
                timestamp: DateTime.now(),
              ),
            );
            _shotsPerDrill[drillId] = shots;
            _currentMapLength[drillId] = mapLength;
          }
        });
        return;
      } on NetworkException catch (e, st) {
        lastNetErr = e;
        _logJson({
          'level': 'error',
          'event': 'recordShot.network_error',
          'attempt': attempt,
          'maxAttempts': maxAttempts,
          'error': _errToJson(e, st),
          'retrying': attempt < maxAttempts,
          'backoffMs': baseDelay.inMilliseconds * attempt,
        });

        if (attempt < maxAttempts) {
          await Future.delayed(
            Duration(milliseconds: baseDelay.inMilliseconds * attempt),
          );
          continue;
        }
      } catch (e, st) {
        _logJson({
          'level': 'error',
          'event': 'recordShot.non_network_error',
          'attempt': attempt,
          'error': _errToJson(e, st),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording shot: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    _logJson({
      'level': 'error',
      'event': 'recordShot.final_failure',
      'maxAttempts': maxAttempts,
      'error': _errToJson(lastNetErr ?? Exception('Network error')),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to record shot after $maxAttempts attempts: ${lastNetErr?.message ?? "Network error"}',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _undoLastShot(String drillId) {
    final hasSubDrills = widget.drillGroup.drills.any(
      (d) => d.id == drillId && d.subDrills.isNotEmpty,
    );
    if (hasSubDrills) return;

    setState(() {
      final shots = _shotsPerDrill[drillId] ?? [];
      if (shots.isNotEmpty) {
        shots.removeLast();
        _shotsPerDrill[drillId] = shots;
        _currentMapLength[drillId] = shots.isEmpty ? 0 : shots.last.mapLength;
      }
    });
  }

  Future<void> _updateSubDrillShots(
    String subDrillId,
    int shots, {
    int? mapLength,
  }) async {
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
      final drillEntryId = widget.drillEntryIdsByDrillId[drillId] ?? drillId;

      if (kDebugMode) {
        debugPrint(
          '[updateSubDrillShots] sessionId=${widget.sessionId} '
          'parentDrillId=$drillId entryId=$drillEntryId '
          'subDrillId=$subDrillId shots=$newShots',
        );
      }

      await _practiceSessionApi.recordShot(
        sessionId: widget.sessionId,
        drillEntryId: drillEntryId,
        matLength: mapLength ?? 1,
        shotNumber: newShots,
        subDrillId: subDrillId,
        useSubDrills: true,
      );

      if (!mounted) return;
      setState(() {
        _subDrillShots[subDrillId] = newShots;
      });

      if (drillName.isNotEmpty && subDrillTitle.isNotEmpty && mounted) {
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
    String drillName = '';
    String subDrillTitle = '';
    for (var drill in widget.drillGroup.drills) {
      final sd = drill.subDrills.firstWhere(
        (x) => x.id == subDrillId,
        orElse: () => SubDrill(
          title: '',
          instruction: '',
          drillId: '',
          id: '',
          createdAt: DateTime.now(),
        ),
      );
      if (sd.id == subDrillId) {
        drillName = drill.name;
        subDrillTitle = sd.title;
        break;
      }
    }

    setState(() {
      if (duration >= 0) {
        _subDrillDurations[subDrillId] = duration;
        _updateTotalTime();
      }
    });

    if (drillName.isNotEmpty && subDrillTitle.isNotEmpty && mounted) {
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

  void _updateTotalTime() {
    int totalMinutes = 0;
    for (var drill in widget.drillGroup.drills) {
      totalMinutes += drill.subDrills.isEmpty
          ? (_drillDurations[drill.id] ?? drill.durationMinutes)
          : drill.subDrills.fold(
              0,
              (sum, sd) => sum + (_subDrillDurations[sd.id] ?? 0),
            );
    }
    _remainingSeconds = totalMinutes * 60;
    _timeController.text = '$totalMinutes:00';
  }

  Future<void> _savePracticeSession() async {
    try {
      final user = await _userRepository.getCurrentUser();
      if (user == null) {
        throw Exception('User not found. Please login first.');
      }

      final drills = widget.drillGroup.drills.map((drill) {
        final subDrillsData = drill.subDrills
            .map(
              (sd) => {
                'id': sd.id,
                'name': sd.title,
                'duration': _subDrillDurations[sd.id] ?? 0,
                'shots': _subDrillShots[sd.id] ?? 0,
              },
            )
            .toList();

        final duration = drill.subDrills.isEmpty
            ? (_drillDurations[drill.id] ?? drill.durationMinutes)
            : subDrillsData.fold(0, (sum, m) => sum + (m['duration'] as int));

        const accuracy = 100;

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

        if (drill.subDrills.isNotEmpty) {
          for (var subDrill in drill.subDrills) {
            final numShots = _subDrillShots[subDrill.id] ?? 0;
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Practice session saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving practice session: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------- UI pieces ----------
  Widget _buildDrillCard(Drill drill) {
    return DrillCard(
      drill: drill,
      shotsPerDrill: _shotsPerDrill,
      subDrillShotsCount: _subDrillShots,
      drillDurations: _drillDurations,
      subDrillDurations: _subDrillDurations,
      currentMapLength: _currentMapLength,
      notesPerDrill: _notesPerDrill,
      onUpdateDrillDuration: _updateDrillDuration,
      onRecordShot: (drillId, v, {subDrillId}) =>
          _recordShot(drillId, v, subDrillId: subDrillId),
      onUndoLastShot: _undoLastShot,
      onNotesChanged: (id, text) => _notesPerDrill[id] = text,
      ringCount: 4,
      drillShotMapSize: 340,
      subDrillShotMapSize: 260,
      compactBreakpoint: 600,
    );
  }

  double get _overallProgress {
    final total = widget.drillGroup.drills.length;
    if (total == 0) return 0;
    // Progress based on paging position (index is 0-based)
    return (_currentDrillIndex + 1) / total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.drillGroup.drills.length;

    return Scaffold(
      // Your custom timer app bar (kept)
      appBar: TimerAppBar(
        remainingSeconds: _remainingSeconds,
        isPaused: _isPaused,
        onPauseToggle: _togglePause,
        onTimeChanged: (secs) => setState(() => _remainingSeconds = secs),
      ),

      body: Column(
        children: [
          // ===== Session Header: group name + progress + timer chip look =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.35),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group title + play/pause quick control
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.drillGroup.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TimerChip(isPaused: _isPaused, onTap: _togglePause),
                  ],
                ),
                const SizedBox(height: 10),
                // Overall progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _overallProgress.clamp(0, 1),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Drill ${_currentDrillIndex + 1} of $total',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      // Show minutes remaining as a hint
                      '${(_remainingSeconds / 60).ceil()} min left',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== Pager =====
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (index) => setState(() {
                _currentDrillIndex = index;
              }),
              itemBuilder: (context, index) {
                final drill = widget.drillGroup.drills[index];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Drill Title Strip
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  drill.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Drill Card (your component)
                            _buildDrillCard(drill),

                            // Space to breathe at bottom so it doesn't clash with nav bar
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ===== Pager Dots + Bottom Action Bar =====
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _PageDots(
                    count: total,
                    index: _currentDrillIndex,
                    onDotTapped: (i) {
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Prev (ghost / tonal)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _currentDrillIndex > 0
                              ? () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Next / Save (primary)
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _currentDrillIndex < total - 1
                              ? ElevatedButton.icon(
                                  key: const ValueKey('next'),
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('Next'),
                                )
                              : ElevatedButton.icon(
                                  key: const ValueKey('save'),
                                  onPressed: _savePracticeSession,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.save_rounded),
                                  label: const Text('Save Session'),
                                ),
                        ),
                      ),
                    ],
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

// ---------- Small UI helpers ----------

class _TimerChip extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onTap;
  const _TimerChip({required this.isPaused, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isPaused ? 'Resume' : 'Pause',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  final ValueChanged<int>? onDotTapped;
  const _PageDots({required this.count, required this.index, this.onDotTapped});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return GestureDetector(
          onTap: onDotTapped == null ? null : () => onDotTapped!(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 8,
            width: active ? 20 : 8,
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withOpacity(0.6),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
