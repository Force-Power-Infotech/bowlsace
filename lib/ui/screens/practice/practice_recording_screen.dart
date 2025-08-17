import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/drill_group_detail.dart';
import '../../../models/practice_session.dart';
import '../../../models/sub_drill.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';

class PracticeRecordingScreen extends StatefulWidget {
  final Drill drill;
  final String drillGroupId;

  const PracticeRecordingScreen({
    Key? key,
    required this.drill,
    required this.drillGroupId,
  }) : super(key: key);

  @override
  State<PracticeRecordingScreen> createState() =>
      _PracticeRecordingScreenState();
}

class _PracticeRecordingScreenState extends State<PracticeRecordingScreen> {
  late Timer _timer;
  int _duration = 0;
  int _currentSubDrillIndex = 0;
  int _shots = 0;
  bool _isPaused = true;
  final TextEditingController _notesController = TextEditingController();
  double _accuracy = 0.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _duration++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _incrementShots() {
    setState(() {
      _shots++;
    });
  }

  void _decrementShots() {
    if (_shots > 0) {
      setState(() {
        _shots--;
      });
    }
  }

  Future<void> _savePracticeSession() async {
    // TODO: Implement actual saving logic
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save practice session')),
      );
      return;
    }

    final session = PracticeSession(
      id: DateTime.now().toIso8601String(), // Replace with actual ID generation
      drillGroupId: widget.drillGroupId,
      drillId: widget.drill.id,
      userId: user.id.toString(),
      duration: _duration,
      shots: _shots,
      notes: _notesController.text,
      accuracy: _accuracy,
      createdAt: DateTime.now(),
    );

    // TODO: Save session to backend
    Navigator.pop(context, session);
  }

  Widget _buildSubDrillCard(SubDrill subDrill) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subDrill.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subDrill.instruction,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (subDrill.numberOfShots != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sports_cricket, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${subDrill.numberOfShots} shots',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(widget.drill.name),
            actions: [
              IconButton(
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: _togglePause,
              ),
            ],
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _decrementShots,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$_shots',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _incrementShots,
                              ),
                            ],
                          ),
                          const Text('Shots'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sub Drills',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.drill.subDrills.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildSubDrillCard(
                        widget.drill.subDrills[_currentSubDrillIndex],
                      ),
                    ),
                  if (widget.drill.subDrills.length > 1) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _currentSubDrillIndex > 0
                              ? () {
                                  setState(() {
                                    _currentSubDrillIndex--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                        ),
                        TextButton.icon(
                          onPressed:
                              _currentSubDrillIndex <
                                  widget.drill.subDrills.length - 1
                              ? () {
                                  setState(() {
                                    _currentSubDrillIndex++;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add notes about your practice session...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Accuracy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _accuracy,
                    onChanged: (value) {
                      setState(() {
                        _accuracy = value;
                      });
                    },
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: '${(_accuracy * 100).round()}%',
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePracticeSession,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Practice Session'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
