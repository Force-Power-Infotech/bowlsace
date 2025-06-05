import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di/service_locator.dart';
import '../../../models/challenge.dart';
import '../../../models/user.dart';
import '../../../models/drill.dart';
import '../../../providers/challenge_provider.dart';
import '../../../providers/drill_provider.dart';
import '../../../repositories/challenge_repository.dart';
import '../../../api/api_error_handler.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Selected values
  User? _selectedOpponent;
  Drill? _selectedDrill;
  DateTime? _selectedDeadline;

  List<User> _availableOpponents = []; // This would be populated from user API
  List<Drill> _availableDrills =
      []; // This would be populated from drill repository

  bool _isLoading = false;
  bool _isLoadingUsers = true;
  bool _isLoadingDrills = true;
  String? _errorMessage;

  final ChallengeRepository _challengeRepository = getIt<ChallengeRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // For this implementation, we'll use mock data since we don't have user lookup API yet
    // In a real implementation, you would fetch users from an API

    // Mock users
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _availableOpponents = [
        User(
          id: 2,
          username: 'john_doe',
          email: 'john@example.com',
          phoneNumber: '+1234567890',
          firstName: 'John',
          lastName: 'Doe',
          createdAt: DateTime.now(),
        ),
        User(
          id: 3,
          username: 'jane_smith',
          email: 'jane@example.com',
          phoneNumber: '+1234567891',
          firstName: 'Jane',
          lastName: 'Smith',
          createdAt: DateTime.now(),
        ),
        User(
          id: 4,
          username: 'bob_jones',
          email: 'bob@example.com',
          phoneNumber: '+1234567892',
          firstName: 'Bob',
          lastName: 'Jones',
          createdAt: DateTime.now(),
        ),
      ];
      _isLoadingUsers = false;
    });

    // Mock drills
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _availableDrills = [
        // Drill(
        //   id: 1,
        //   name: 'Draw Shot',
        //   description: 'Deliver your bowl as close as possible to the jack',
        //   difficulty: 2.0,
        //   tags: ['Accuracy', 'Control'],
        //   createdAt: DateTime.now(),
        //   imageUrl: 'assets/images/drills/draw_shot.jpg',
        //   durationMinutes: 15,
        // ),
        // Drill(
        //   id: 2,
        //   name: 'Drive Shot',
        //   description: 'A fast and powerful shot to remove opponent\'s bowls',
        //   difficulty: 3.0,
        //   tags: ['Power', 'Speed'],
        //   createdAt: DateTime.now(),
        //   imageUrl: 'assets/images/drills/drive_shot.jpg',
        //   durationMinutes: 20,
        // ),
        // Drill(
        //   id: 3,
        //   name: 'Trail Shot',
        //   description:
        //       'Move the jack to a new position while following with your bowl',
        //   difficulty: 4.0,
        //   tags: ['Precision', 'Advanced'],
        //   createdAt: DateTime.now(),
        //   imageUrl: 'assets/images/drills/trail_shot.jpg',
        //   durationMinutes: 25,
        // ),
      ];
      _isLoadingDrills = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _sendChallenge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedOpponent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an opponent')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final challengeData = ChallengeCreate(
        recipientId: _selectedOpponent!.id,
        drillId: _selectedDrill?.id,
        completionDeadline: _selectedDeadline,
      );

      final challenge = await _challengeRepository.sendChallenge(challengeData);

      if (!mounted) return;

      // Add the new challenge to the provider
      Provider.of<ChallengeProvider>(
        context,
        listen: false,
      ).addSentChallenge(challenge);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge sent successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back
      Navigator.of(context).pop();
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to send challenge';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Challenge')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Opponent Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Opponent',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _isLoadingUsers
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : DropdownButtonFormField<User>(
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Opponent*',
                                      hintText: 'Select a player to challenge',
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    value: _selectedOpponent,
                                    items: _availableOpponents.map((User user) {
                                      return DropdownMenuItem<User>(
                                        value: user,
                                        child: Text(
                                          '${user.firstName} ${user.lastName}',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (User? newValue) {
                                      setState(() {
                                        _selectedOpponent = newValue;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select an opponent';
                                      }
                                      return null;
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Drill Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Drill (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Specify a drill for this challenge or leave blank for a free challenge',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _isLoadingDrills
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : DropdownButtonFormField<Drill>(
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Drill',
                                      hintText: 'Select a drill (optional)',
                                      prefixIcon: Icon(Icons.sports),
                                    ),
                                    value: _selectedDrill,
                                    items: [
                                      const DropdownMenuItem<Drill>(
                                        value: null,
                                        child: Text('No specific drill'),
                                      ),
                                      ..._availableDrills.map((Drill drill) {
                                        return DropdownMenuItem<Drill>(
                                          value: drill,
                                          child: Text(drill.name),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (Drill? newValue) {
                                      setState(() {
                                        _selectedDrill = newValue;
                                      });
                                    },
                                  ),
                            if (_selectedDrill != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDrill!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_selectedDrill!.description),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.fitness_center,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Difficulty: ${_getDifficultyText(_selectedDrill!.difficulty)}',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.tag, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tags: ${_selectedDrill!.tags.join(", ")}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deadline Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set Deadline (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Completion Deadline',
                                  hintText: 'Tap to select a deadline',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDeadline != null
                                          ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                                          : 'No deadline set',
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Send button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendChallenge,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('SEND CHALLENGE'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getDifficultyText(double level) {
    if (level <= 1.5) return 'Easy';
    if (level <= 2.5) return 'Moderate';
    if (level <= 3.5) return 'Challenging';
    if (level <= 4.5) return 'Difficult';
    return 'Expert';
  }
}
