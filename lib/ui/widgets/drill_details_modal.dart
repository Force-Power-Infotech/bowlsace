import 'package:flutter/material.dart';
import '../../models/drill.dart';
import '../../di/service_locator.dart';
import '../../repositories/drill_repository.dart';

class DrillDetailsModal extends StatefulWidget {
  final int drillId;

  const DrillDetailsModal({super.key, required this.drillId});

  @override
  State<DrillDetailsModal> createState() => _DrillDetailsModalState();
}

class _DrillDetailsModalState extends State<DrillDetailsModal> {
  Drill? _drill;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDrillDetails();
  }

  Future<void> _loadDrillDetails() async {
    try {      
      if (widget.drillId <= 0) {
        throw Exception('Invalid drill ID');
      }
      
      final drillRepo = getIt<DrillRepository>();
      final drill = await drillRepo.getDrill(widget.drillId);
      
      setState(() {
        _drill = drill;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load drill details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            )
          else if (_drill != null) ...[
            // Drill title
            Text(
              _drill!.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Drill info cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Icon(Icons.timer, color: theme.colorScheme.primary),
                          const SizedBox(height: 4),
                          Text('${_drill!.durationMinutes} min'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Icon(Icons.star, color: theme.colorScheme.primary),
                          const SizedBox(height: 4),
                          Text('${_drill!.difficulty}/5'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Icon(Icons.sports, color: theme.colorScheme.primary),
                          const SizedBox(height: 4),
                          Text('${_drill!.targetScore}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Description',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _drill!.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Tags
            if (_drill!.tags.isNotEmpty) ...[
              Text(
                'Tags',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _drill!.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
          
          // Add some bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

void showDrillDetailsModal(BuildContext context, int drillId) {
  // Validate drill ID
  if (drillId <= 0) {
    // Show error snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot show drill details: Invalid ID'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SingleChildScrollView(
      child: DrillDetailsModal(drillId: drillId),
    ),
  );
}
