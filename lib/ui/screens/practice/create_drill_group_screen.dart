import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/drill_group.dart';
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
  final _imageUrlController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedCategory = 'Beginner';
  double _difficulty = 3.0;
  Color _accentColor = Colors.blue;
  bool _isLoading = false;

  final PracticeRepository _practiceRepository = getIt<PracticeRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  final List<String> _categories = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
    'Custom',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _accentColor,
              onColorChanged: (Color color) {
                setState(() {
                  _accentColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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

      final drillGroup = DrillGroup(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: _imageUrlController.text,
        accentColor: _accentColor,
        drills: [], // Start with empty drills list
        createdAt: DateTime.now(),
        isCustom: true,
        category: _selectedCategory,
        totalDuration: 0, // Will be updated when drills are added
        difficulty: _difficulty,
        tags: tags,
      );

      // Save to repository
      await _practiceRepository.createDrillGroup(drillGroup);

      if (!mounted) return;

      // Update provider
      Provider.of<PracticeProvider>(
        context,
        listen: false,
      ).addDrillGroup(drillGroup);

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

                    // Image URL
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Cover Image URL*',
                        hintText: 'Enter a URL for the cover image',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an image URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
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
                          divisions: 8,
                          label: _difficulty.toStringAsFixed(1),
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
                    const SizedBox(height: 16),

                    // Color Picker Button
                    ElevatedButton.icon(
                      onPressed: _pickColor,
                      icon: Icon(Icons.color_lens, color: _accentColor),
                      label: const Text('Choose Accent Color'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor.withOpacity(0.1),
                        foregroundColor: _accentColor,
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
