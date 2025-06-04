import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di/service_locator.dart';
import '../../../models/practice_session.dart';
import '../../../models/drill_group.dart';
import '../../../models/drill.dart';
import '../../../providers/practice_provider.dart';
import '../../../repositories/practice_repository.dart';
import '../../../api/api_error_handler.dart';

class CreatePracticeScreen extends StatefulWidget {
  final DrillGroup? drillGroup;
  final Drill? selectedDrill;

  const CreatePracticeScreen({super.key, this.drillGroup, this.selectedDrill});

  @override
  State<CreatePracticeScreen> createState() => _CreatePracticeScreenState();
}

class _CreatePracticeScreenState extends State<CreatePracticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  var _durationMinutes = 30; // Default duration in minutes

  bool _isLoading = false;
  String? _errorMessage;

  final PracticeRepository _practiceRepository = getIt<PracticeRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createPractice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = SessionCreate(
        name: _nameController.text,
        location: _locationController.text.isEmpty
            ? null
            : _locationController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        durationMinutes: _durationMinutes,
      );

      final session = await _practiceRepository.createSession(data);

      if (!mounted) return;

      // Use the provider to add the new session
      Provider.of<PracticeProvider>(context, listen: false).addSession(session);

      // Navigate to the practice details screen
      Navigator.of(
        context,
      ).pushReplacementNamed('/practice/details', arguments: session);
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to create practice session';
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
      appBar: AppBar(title: const Text('New Practice Session')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Session Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Session Name*',
                        hintText: 'e.g., Morning Practice, Draw Training',
                        prefixIcon: Icon(Icons.sports),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name for this session';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                        hintText: 'e.g., City Bowls Club',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Duration
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Duration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('$_durationMinutes minutes'),
                            Slider(
                              min: 5,
                              max: 180,
                              divisions: 35,
                              label: '$_durationMinutes mins',
                              value: _durationMinutes.toDouble(),
                              onChanged: (value) {
                                setState(() {
                                  _durationMinutes = value.toInt();
                                });
                              },
                            ),
                            // Quick presets
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _DurationPresetButton(
                                  minutes: 15,
                                  selectedMinutes: _durationMinutes,
                                  onTap: () {
                                    setState(() {
                                      _durationMinutes = 15;
                                    });
                                  },
                                ),
                                _DurationPresetButton(
                                  minutes: 30,
                                  selectedMinutes: _durationMinutes,
                                  onTap: () {
                                    setState(() {
                                      _durationMinutes = 30;
                                    });
                                  },
                                ),
                                _DurationPresetButton(
                                  minutes: 60,
                                  selectedMinutes: _durationMinutes,
                                  onTap: () {
                                    setState(() {
                                      _durationMinutes = 60;
                                    });
                                  },
                                ),
                                _DurationPresetButton(
                                  minutes: 90,
                                  selectedMinutes: _durationMinutes,
                                  onTap: () {
                                    setState(() {
                                      _durationMinutes = 90;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Any goals or focus areas for this session?',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
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

                    // Create button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createPractice,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('START PRACTICE'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DurationPresetButton extends StatelessWidget {
  final int minutes;
  final int selectedMinutes;
  final VoidCallback onTap;

  const _DurationPresetButton({
    required this.minutes,
    required this.selectedMinutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = minutes == selectedMinutes;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
