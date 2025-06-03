import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di/service_locator.dart';
import '../../../models/practice_session.dart';
import '../../../models/shot.dart';
import '../../../providers/practice_provider.dart';
import '../../../repositories/practice_repository.dart';
import '../../../api/api_error_handler.dart';

class PracticeDetailsScreen extends StatefulWidget {
  final Session session;

  const PracticeDetailsScreen({super.key, required this.session});

  @override
  State<PracticeDetailsScreen> createState() => _PracticeDetailsScreenState();
}

class _PracticeDetailsScreenState extends State<PracticeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAddingShot = false;

  // Shot tracking
  final _drillTypeController = TextEditingController();
  ShotResult _selectedResult = ShotResult.success;
  final _shotNotesController = TextEditingController();

  final PracticeRepository _practiceRepository = getIt<PracticeRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSessionDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _drillTypeController.dispose();
    _shotNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // The repository should have a method to get a single session with details
      // For now we'll use the current provider session
      final provider = Provider.of<PracticeProvider>(context, listen: false);
      if (provider.currentSession?.id != widget.session.id) {
        provider.setCurrentSession(widget.session);
      }

      // If needed, you could implement a method to load more details
      // Like: final sessionDetails = await _practiceRepository.getSessionDetails(widget.session.id);

      // For demonstration purposes, we'll simulate a delay
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load session details';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addShot() async {
    if (_drillTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a drill type')),
      );
      return;
    }

    setState(() {
      _isAddingShot = true;
    });

    try {
      // Create a new shot
      final shot = Shot(
        id: -DateTime.now().millisecondsSinceEpoch, // Temporary ID until synced
        sessionId: widget.session.id,
        drillType: _drillTypeController.text,
        result: _selectedResult,
        notes: _shotNotesController.text.isEmpty
            ? null
            : _shotNotesController.text,
        timestamp: DateTime.now(),
      );

      // Add to repository
      await _practiceRepository.addShot(widget.session.id, shot);

      // Update the current session in the provider
      if (!mounted) return;

      final provider = Provider.of<PracticeProvider>(context, listen: false);
      // Get sessions from repository and find the updated one
      final sessions = await _practiceRepository.getSessions();
      final updatedSession = sessions.firstWhere(
        (s) => s.id == widget.session.id,
        orElse: () => widget.session,
      );

      provider.setCurrentSession(updatedSession);

      // Clear inputs
      _drillTypeController.clear();
      _shotNotesController.clear();
      setState(() {
        _selectedResult = ShotResult.success;
      });

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shot recorded')));
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record shot: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingShot = false;
        });
      }
    }
  }

  Future<void> _deleteShot(Shot shot) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete the shot from the repository
      await _practiceRepository.deleteShot(widget.session.id, shot.id);

      // Update the current session in the provider
      if (!mounted) return;

      final provider = Provider.of<PracticeProvider>(context, listen: false);
      // Get updated sessions from repository
      final sessions = await _practiceRepository.getSessions();
      final updatedSession = sessions.firstWhere(
        (s) => s.id == widget.session.id,
        orElse: () => widget.session,
      );

      provider.setCurrentSession(updatedSession);

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shot deleted')));
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete shot: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditShotModal(Shot shot) {
    _drillTypeController.text = shot.drillType;
    _selectedResult = shot.result;
    _shotNotesController.text = shot.notes ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Shot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Drill Type
            TextFormField(
              controller: _drillTypeController,
              decoration: const InputDecoration(
                labelText: 'Drill Type*',
                hintText: 'e.g., Draw to Jack, Drive, etc.',
              ),
            ),
            const SizedBox(height: 16),

            // Result Selection
            const Text('Result:'),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setModalState) {
                return Row(
                  children: [
                    _ResultButton(
                      result: ShotResult.success,
                      selectedResult: _selectedResult,
                      onTap: () {
                        setModalState(() {
                          _selectedResult = ShotResult.success;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _ResultButton(
                      result: ShotResult.partial,
                      selectedResult: _selectedResult,
                      onTap: () {
                        setModalState(() {
                          _selectedResult = ShotResult.partial;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _ResultButton(
                      result: ShotResult.miss,
                      selectedResult: _selectedResult,
                      onTap: () {
                        setModalState(() {
                          _selectedResult = ShotResult.miss;
                        });
                        setState(() {});
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _shotNotesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any observations about this shot?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Update Button
            ElevatedButton(
              onPressed: _isAddingShot
                  ? null
                  : () {
                      Navigator.pop(context);
                      _updateShot(shot);
                    },
              child: _isAddingShot
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('UPDATE SHOT'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _updateShot(Shot existingShot) async {
    if (_drillTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a drill type')),
      );
      return;
    }

    setState(() {
      _isAddingShot = true;
    });

    try {
      // Create an updated shot
      final updatedShot = Shot(
        id: existingShot.id,
        sessionId: existingShot.sessionId,
        drillType: _drillTypeController.text,
        result: _selectedResult,
        notes: _shotNotesController.text.isEmpty
            ? null
            : _shotNotesController.text,
        timestamp: existingShot.timestamp,
      );

      // Update in repository
      await _practiceRepository.updateShot(widget.session.id, updatedShot);

      // Update the current session in the provider
      if (!mounted) return;

      final provider = Provider.of<PracticeProvider>(context, listen: false);
      // Get sessions from repository and find the updated one
      final sessions = await _practiceRepository.getSessions();
      final updatedSession = sessions.firstWhere(
        (s) => s.id == widget.session.id,
        orElse: () => widget.session,
      );

      provider.setCurrentSession(updatedSession);

      // Clear inputs
      _drillTypeController.clear();
      _shotNotesController.clear();
      setState(() {
        _selectedResult = ShotResult.success;
      });

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shot updated')));
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update shot: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingShot = false;
        });
      }
    }
  }

  void _showAddShotModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Record a Shot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Drill Type
            TextFormField(
              controller: _drillTypeController,
              decoration: const InputDecoration(
                labelText: 'Drill Type*',
                hintText: 'e.g., Draw to Jack, Drive, etc.',
              ),
            ),
            const SizedBox(height: 16),

            // Result Selection
            const Text('Result:'),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setModalState) {
                return Row(
                  children: [
                    _ResultButton(
                      result: ShotResult.success,
                      selectedResult: _selectedResult,
                      onTap: () {
                        setModalState(() {
                          _selectedResult = ShotResult.success;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _ResultButton(
                      result: ShotResult.partial,
                      selectedResult: _selectedResult,
                      onTap: () {
                        setModalState(() {
                          _selectedResult = ShotResult.partial;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _ResultButton(
                      result: ShotResult.miss,
                      selectedResult: _selectedResult,
                      onTap: () {
                        setModalState(() {
                          _selectedResult = ShotResult.miss;
                        });
                        setState(() {});
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _shotNotesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any observations about this shot?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Save Button
            ElevatedButton(
              onPressed: _isAddingShot
                  ? null
                  : () {
                      Navigator.pop(context);
                      _addShot();
                    },
              child: _isAddingShot
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SAVE SHOT'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final practiceProvider = Provider.of<PracticeProvider>(context);
    final session = practiceProvider.currentSession ?? widget.session;
    final shots = session.shots ?? [];

    // Count success, partial, and miss shots
    final successCount = shots
        .where((s) => s.result == ShotResult.success)
        .length;
    final partialCount = shots
        .where((s) => s.result == ShotResult.partial)
        .length;
    final missCount = shots.where((s) => s.result == ShotResult.miss).length;
    final totalShots = shots.length;

    // Calculate success rate
    final successRate = totalShots > 0
        ? (successCount / totalShots * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(session.name),
            if (session.isCompleted)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
          ],
        ),
        actions: [
          // Complete session button
          if (!session.isCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Complete Session',
              onPressed: () => _showCompleteSessionDialog(session),
            ),
          // More options menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditSessionDialog(session);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit Session'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Shots'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSessionDetails,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Session Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time),
                                  const SizedBox(width: 8),
                                  Text('${session.durationMinutes} minutes'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (session.location != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.location_on),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(session.location!)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 8),
                                  Text(_formatDate(session.createdAt)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Performance Stats
                      const Text(
                        'Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Success Rate
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Success Rate'),
                                  Text(
                                    '$successRate%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: totalShots > 0
                                      ? successCount / totalShots
                                      : 0,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey[300],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Shot Stats
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatItem(
                                    label: 'Success',
                                    value: successCount.toString(),
                                    color: Colors.green,
                                  ),
                                  _StatItem(
                                    label: 'Partial',
                                    value: partialCount.toString(),
                                    color: Colors.orange,
                                  ),
                                  _StatItem(
                                    label: 'Miss',
                                    value: missCount.toString(),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Add more sections as needed
                    ],
                  ),
                ),

                // Shots Tab
                shots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No shots recorded yet'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _showAddShotModal,
                              child: const Text('Record a Shot'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: shots.length,
                        itemBuilder: (context, index) {
                          final shot = shots[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                            child: Dismissible(
                              key: Key('shot-${shot.id}'),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text(
                                      'Are you sure you want to delete this shot?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('DELETE'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) {
                                _deleteShot(shot);
                              },
                              child: ListTile(
                                leading: _getResultIcon(shot.result),
                                title: Text(shot.drillType),
                                subtitle: shot.notes != null
                                    ? Text(shot.notes!)
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(shot.timestamp),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _showEditShotModal(shot),
                                      tooltip: 'Edit shot',
                                    ),
                                  ],
                                ),
                                onTap: () => _showEditShotModal(shot),
                              ),
                            ),
                          );
                        },
                      ),

                // Notes Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Session Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              session.notes != null && session.notes!.isNotEmpty
                                  ? Text(session.notes!)
                                  : const Text(
                                      'No notes for this session',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                              const SizedBox(height: 16),
                              if (!session.isCompleted)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.edit_note, size: 16),
                                  label: const Text('Edit Notes'),
                                  onPressed: () =>
                                      _showEditNotesDialog(session),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddShotModal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getResultIcon(ShotResult result) {
    switch (result) {
      case ShotResult.success:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        );
      case ShotResult.partial:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.remove, color: Colors.white),
        );
      case ShotResult.miss:
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.close, color: Colors.white),
        );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCompleteSessionDialog(Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Session'),
        content: const Text(
          'Would you like to mark this session as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeSession(session);
            },
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSession(Session session) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create session update data
      final update = SessionUpdate(isCompleted: true);

      // Update in repository
      await _practiceRepository.updateSession(session.id, update);

      // Update in provider
      if (!mounted) return;

      final provider = Provider.of<PracticeProvider>(context, listen: false);
      final sessions = await _practiceRepository.getSessions();
      final updatedSession = sessions.firstWhere(
        (s) => s.id == session.id,
        orElse: () => session,
      );

      provider.setCurrentSession(updatedSession);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session marked as completed')),
      );
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete session: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditSessionDialog(Session session) {
    final nameController = TextEditingController(text: session.name);
    final locationController = TextEditingController(
      text: session.location ?? '',
    );
    final durationController = TextEditingController(
      text: session.durationMinutes.toString(),
    );
    final notesController = TextEditingController(text: session.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Session Name*'),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)*',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              // Validate inputs
              final name = nameController.text.trim();
              final location = locationController.text.trim();
              final durationText = durationController.text.trim();
              final notes = notesController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a session name')),
                );
                return;
              }

              if (durationText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a duration')),
                );
                return;
              }

              final duration = int.tryParse(durationText);
              if (duration == null || duration <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid duration'),
                  ),
                );
                return;
              }

              Navigator.of(context).pop();

              // Create update data
              final update = SessionUpdate(
                name: name,
                location: location.isNotEmpty ? location : null,
                notes: notes.isNotEmpty ? notes : null,
                durationMinutes: duration,
              );

              _updateSession(session, update);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditNotesDialog(Session session) {
    final notesController = TextEditingController(text: session.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notes'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Session Notes',
            hintText:
                'Enter any observations or notes about this practice session',
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Update session with new notes
              final update = SessionUpdate(notes: notesController.text);
              _updateSession(session, update);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSession(Session session, SessionUpdate update) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update in repository
      await _practiceRepository.updateSession(session.id, update);

      // Update in provider
      if (!mounted) return;

      final provider = Provider.of<PracticeProvider>(context, listen: false);
      final sessions = await _practiceRepository.getSessions();
      final updatedSession = sessions.firstWhere(
        (s) => s.id == session.id,
        orElse: () => session,
      );

      provider.setCurrentSession(updatedSession);

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session updated')));
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update session: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}

class _ResultButton extends StatelessWidget {
  final ShotResult result;
  final ShotResult selectedResult;
  final VoidCallback onTap;

  const _ResultButton({
    required this.result,
    required this.selectedResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (result) {
      case ShotResult.success:
        color = Colors.green;
        icon = Icons.check;
        label = 'Success';
        break;
      case ShotResult.partial:
        color = Colors.orange;
        icon = Icons.remove;
        label = 'Partial';
        break;
      case ShotResult.miss:
        color = Colors.red;
        icon = Icons.close;
        label = 'Miss';
        break;
    }

    final isSelected = result == selectedResult;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
