import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/practice_provider.dart';
import '../../../di/service_locator.dart';
import '../../../repositories/practice_repository.dart';
import '../../../api/api_error_handler.dart';

class CreateDrillGroupScreen extends StatefulWidget {
  const CreateDrillGroupScreen({super.key});

  @override
  State<CreateDrillGroupScreen> createState() => _CreateDrillGroupScreenState();
}

class _CreateDrillGroupScreenState extends State<CreateDrillGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  double _difficulty = 3.0;
  bool _isLoading = false;

  final PracticeRepository _practiceRepository = getIt<PracticeRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _createDrillGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final groupData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'is_public': true,
        'difficulty': _difficulty.toInt(),
        'tags': tags,
        'drill_ids': [], // Fixed: using drill_ids instead of drills to match API
      };

      // Create drill group using repository
      final createdGroup = await _practiceRepository.createDrillGroup(
        groupData,
      );

      if (!mounted) return;

      // Update provider with the created group
      Provider.of<PracticeProvider>(
        context,
        listen: false,
      ).addDrillGroup(createdGroup);

      // Show success and pop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drill group created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      _errorHandler.handleError(e);
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
      appBar: AppBar(title: const Text('Create Drill Group')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name*',
                        hintText: 'e.g., Draw Shot Mastery',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description*',
                        hintText:
                            'Describe what this group of drills is about...',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Difficulty Slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Difficulty: ${_difficulty.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: _difficulty,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _difficulty.toStringAsFixed(0),
                          onChanged: (value) {
                            setState(() {
                              _difficulty = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Enter tags separated by commas',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create Button
                    ElevatedButton(
                      onPressed: _createDrillGroup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('CREATE DRILL GROUP'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ColorPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final colorGroup in _colorGroups)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: colorGroup.map((color) {
                return GestureDetector(
                  onTap: () => onColorChanged(color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == pickerColor
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

const _colorGroups = [
  [Colors.red, Colors.pink, Colors.purple, Colors.deepPurple, Colors.indigo],
  [Colors.blue, Colors.lightBlue, Colors.cyan, Colors.teal, Colors.green],
  [Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber, Colors.orange],
  [Colors.deepOrange, Colors.brown, Colors.grey, Colors.blueGrey, Colors.black],
];
