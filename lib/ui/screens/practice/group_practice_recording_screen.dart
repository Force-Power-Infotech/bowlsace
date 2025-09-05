import 'dart:async';
import 'dart:convert';

import 'package:bowlsace/api/api_client.dart';
import 'package:bowlsace/models/sub_drill.dart';
import 'package:bowlsace/ui/widgets/appbar.dart';
import 'package:bowlsace/ui/widgets/uihelpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../models/drill_group_detail.dart'; // DrillGroupDetail / Drill / SubDrill
import '../../../models/shot_record.dart';
import '../../../models/practice_session_detail.dart'; // Detail models we added
import '../../../repositories/user_repository.dart';
import '../../../api/services/practice_session_api.dart';

import '../../../di/service_locator.dart';
import '../../widgets/drill_card.dart';

class GroupPracticeRecordingScreen extends StatefulWidget {
  final String sessionId;

  const GroupPracticeRecordingScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<GroupPracticeRecordingScreen> createState() =>
      _GroupPracticeRecordingScreenState();
}

class _GroupPracticeRecordingScreenState
    extends State<GroupPracticeRecordingScreen> {
  late final UserRepository _userRepository;
  late final PracticeSessionApi _practiceSessionApi;

  // Loading + server state
  bool _isLoadingDetails = true;
  PracticeSessionDetail? _sessionDetail;
  late Map<String, String> _entryIdByDrillId; // drill_id (catalog) -> drill entry id (session)
  DrillGroupDetail? _drillGroupView;          // Adapted from server detail for UI

  // Paging / progress
  late final PageController _pageController;
  int _currentDrillIndex = 0;

  // Drill + subdrill state
  final Map<String, List<ShotRecord>> _shotsPerDrill = {}; // keyed by drill_id
  final Map<String, String> _notesPerDrill = {};           // keyed by drill_id
  final Map<String, int> _currentMapLength = {};           // keyed by drill_id or sub_drill_id
  final Map<String, int> _subDrillShots = {};              // keyed by sub_drill_id
  final Map<String, int> _subDrillDurations = {};          // keyed by sub_drill_id (minutes)
  final Map<String, int> _drillDurations = {};             // keyed by drill_id (minutes)

  // Time control
  late final TextEditingController _timeController;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isPaused = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _userRepository = getIt<UserRepository>();
    _practiceSessionApi = getIt<PracticeSessionApi>();
    _entryIdByDrillId = {};
    _timeController = TextEditingController(text: '0:00');

    _loadSessionDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ---------- Server load & hydration ----------
  Future<void> _loadSessionDetails() async {
    try {
      final detail = await _practiceSessionApi.getPracticeSessionById(
        sessionId: widget.sessionId,
      );

      // Build authoritative mapping drill_id -> session drill entry id
      final serverMap = detail.buildEntryIdMap();
      _entryIdByDrillId.addAll(serverMap);

      // Adapt fetched drills into your UI Drill/DrillGroupDetail models
      final adapted = _adaptToDrillGroup(detail);

      // Hydrate durations, notes, shots, and current mat lengths from server
      for (final dEntry in detail.drills) {
        // Duration (minutes) from server seconds
        _drillDurations[dEntry.drillId] =
            (dEntry.durationSeconds / 60).ceil();

        // Notes
        _notesPerDrill[dEntry.drillId] = dEntry.notes;

        // Drill shot_list -> our ShotRecord[]
        if (dEntry.shotList.isNotEmpty) {
          final converted = dEntry.shotList.asMap().entries.map((e) {
            final s = e.value;
            return ShotRecord(
              mapLength: s.matLength ?? 0,
              shotNumber: s.shotNumber ?? (e.key + 1),
              timestamp: s.createdAt ?? DateTime.now(),
            );
          }).toList();
          _shotsPerDrill[dEntry.drillId] = converted;
          _currentMapLength[dEntry.drillId] =
              converted.isNotEmpty ? converted.last.mapLength : 0;
        } else {
          _shotsPerDrill[dEntry.drillId] = [];
          _currentMapLength[dEntry.drillId] = 0;
        }

        // Sub-drills: shots, durations, last mat length if provided later
        for (final sd in dEntry.subDrills) {
          _subDrillShots[sd.subDrillId] = sd.shots;
          _subDrillDurations[sd.subDrillId] =
              (sd.durationSeconds / 60).ceil();
          if (sd.shotList.isNotEmpty) {
            _currentMapLength[sd.subDrillId] =
                sd.shotList.last.matLength ?? 0;
          }
        }
      }

      // Compute total planned minutes -> remainingSeconds
      _recomputeRemainingSeconds(adapted);

      if (!mounted) return;
      setState(() {
        _sessionDetail = detail;
        _drillGroupView = adapted;
        _isLoadingDetails = false;
      });
    } catch (e, st) {
      _logJson({
        'level': 'error',
        'event': 'loadSessionDetails.error',
        'error': _errToJson(e, st),
      });
      if (!mounted) return;
      setState(() => _isLoadingDetails = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load session: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  DrillGroupDetail _adaptToDrillGroup(PracticeSessionDetail detail) {
    // Convert DrillEntryOut -> your UI Drill/SubDrill
    int computedGroupMinutes = 0;

    final drills = detail.drills.map((de) {
      final subDrills = de.subDrills.map((sd) {
        final subMinutes = (sd.durationSeconds / 60).ceil();
        return SubDrill(
          id: sd.id,
          title: sd.title,
          duration: subMinutes,
          numberOfShots: sd.shots,
          instruction: '',
          drillId: de.id,                                   // link to parent
          createdAt: detail.createdAt ?? DateTime.now(),          // ensure non-null
        );
      }).toList();

      // Prefer drill duration from API; fall back to sum of subdrills if present
      final drillMinutes = (de.durationSeconds / 60).ceil();
      final minutesForGroup =
          subDrills.isEmpty ? drillMinutes : subDrills.fold<int>(0, (s, sd) => s + (sd.duration ?? 0));
      computedGroupMinutes += minutesForGroup;

      return Drill(
        id: de.id,
        name: de.name,
        durationMinutes: drillMinutes,
        subDrills: subDrills,

        // Extra fields required by your model (non-null):
        description: '',
        difficulty: 0,                 // safe default int
        isActive: true,                // safe default bool
        drillType: 'session',          // harmless label
        drillGroupId: detail.drillGroupId,
      );
    }).toList();

    final sessionMinutes = (detail.totalDurationSeconds / 60).ceil();
    final groupMinutes = sessionMinutes > 0 ? sessionMinutes : computedGroupMinutes;

    return DrillGroupDetail(
      id: detail.drillGroupId,
      name: detail.drillGroupName,
      drills: drills,

      // Extra fields required by your model (non-null):
      description: '',
      difficulty: 0,                                   // safe default int
      isPublic: false,                                 // safe default bool
      tags: const [],
      metaDrillGroupId: detail.drillGroupId,
      userId: int.tryParse(detail.userId) ?? 0,        // convert string -> int
      createdAt: detail.createdAt ?? DateTime.now(),   // ensure non-null
      updatedAt: detail.createdAt ?? DateTime.now(),   // no updated_at in API
      durationMinutes: groupMinutes,
    );
  }

  void _recomputeRemainingSeconds(DrillGroupDetail group) {
    int totalMinutes = 0;
    for (final d in group.drills) {
      if (d.subDrills.isEmpty) {
        totalMinutes += _drillDurations[d.id] ?? d.durationMinutes;
      } else {
        totalMinutes += d.subDrills.fold<int>(
          0,
          (sum, sd) => sum + (_subDrillDurations[sd.id] ?? sd.duration ?? 0),
        );
      }
    }
    _remainingSeconds = totalMinutes * 60;
    _timeController.text = '$totalMinutes:00';
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
        content: const Text('Great job! You can finish this session now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Practice'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Finish'),
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

    // Use authoritative mapping from server
    final drillEntryId = _entryIdByDrillId[drillId] ?? drillId;

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
            'hasEntryIdMapping': _entryIdByDrillId.containsKey(drillId),
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
    final group = _drillGroupView;
    if (group == null) return;

    final hasSubDrills = group.drills.any(
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

  void _updateDrillDuration(String drillId, int duration) {
    setState(() {
      if (duration >= 0) {
        _drillDurations[drillId] = duration;
        final group = _drillGroupView;
        if (group != null) _recomputeRemainingSeconds(group);
      }
    });
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
    final total = _drillGroupView?.drills.length ?? 0;
    if (total == 0) return 0;
    return (_currentDrillIndex + 1) / total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = _drillGroupView;
    final total = group?.drills.length ?? 0;

    return Scaffold(
      appBar: TimerAppBar(
        remainingSeconds: _remainingSeconds,
        isPaused: _isLoadingDetails ? true : _isPaused,
        onPauseToggle: _isLoadingDetails ? () {} : _togglePause, // never null
        onTimeChanged: (secs) => setState(() => _remainingSeconds = secs),
      ),

      body: Column(
        children: [
          // Header
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
                // Group title + play/pause
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group?.name ?? 'Loading…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!_isLoadingDetails)
                      TimerChip(isPaused: _isPaused, onTap: _togglePause),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: total == 0 ? null : _overallProgress.clamp(0, 1),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      total == 0
                          ? 'Loading drills…'
                          : 'Drill ${_currentDrillIndex + 1} of $total',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
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

          // Pager
          Expanded(
            child: Stack(
              children: [
                if (group != null && total > 0)
                  PageView.builder(
                    controller: _pageController,
                    itemCount: total,
                    onPageChanged: (index) =>
                        setState(() => _currentDrillIndex = index),
                    itemBuilder: (context, index) {
                      final drill = group.drills[index];
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
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer
                                            .withOpacity(0.35),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        drill.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  _buildDrillCard(drill),

                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                if (_isLoadingDetails)
                  Container(
                    color: theme.colorScheme.surface.withOpacity(0.6),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),

          // Dots + bottom actions
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  PageDots(
                    count: total,
                    index: total == 0 ? 0 : _currentDrillIndex,
                    onDotTapped: (i) {
                      if (total == 0) return;
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
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (total == 0 || _currentDrillIndex == 0)
                              ? null
                              : () {
                                  _pageController.previousPage(
                                    duration:
                                        const Duration(milliseconds: 260),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            foregroundColor:
                                theme.colorScheme.onSurfaceVariant,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: (total == 0 || _currentDrillIndex < total - 1)
                              ? ElevatedButton.icon(
                                  key: const ValueKey('next'),
                                  onPressed: total == 0
                                      ? null
                                      : () {
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
                                  icon: const Icon(
                                      Icons.arrow_forward_rounded),
                                  label: const Text('Next'),
                                )
                              : ElevatedButton.icon(
                                  key: const ValueKey('finish'),
                                  onPressed: () {
                                    if (mounted) Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Finish'),
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
