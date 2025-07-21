import 'package:flutter/material.dart';
import '../../../di/service_locator.dart';
import '../../../repositories/search_repository.dart';
import '../../../api/services/search_api.dart';
import '../../../api/services/drill_group_api.dart';
import '../../widgets/drill_details_modal.dart';
import '../practice/drill_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResult> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  hintText: 'Search...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) async {
                  if (value.isEmpty) {
                    setState(() {
                      _results = [];
                      _error = null;
                    });
                    return;
                  }
                  
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  
                  try {
                    final searchRepo = getIt<SearchRepository>();
                    final response = await searchRepo.search(value);
                    setState(() {
                      _results = response.items;
                      _isLoading = false;
                    });
                  } catch (e) {
                    setState(() {
                      _error = 'Search failed. Please try again.';
                      _isLoading = false;
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ),
      body: _controller.text.isEmpty
          ? Center(
              child: Text(
                'Type to search...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: theme.colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try searching with different keywords',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(result.name),
                            subtitle: result.description.isNotEmpty 
                                ? Text(result.description) 
                                : null,
                            leading: Icon(
                              result.type == 'drill_group' 
                                  ? Icons.group 
                                  : Icons.sports,
                            ),
                            onTap: () async {
                              if (result.type == 'drill') {
                                showDrillDetailsModal(context, result.id);
                              } else if (result.type == 'drill_group') {
                                try {
                                  // Get the drill group API
                                  final drillGroupApi = getIt<DrillGroupApi>();
                                  
                                  // Show a loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                  
                                  // Get drill group details
                                  final drillGroup = await drillGroupApi.getDrillGroup(result.id);
                                  
                                  // Navigate to the drill list screen
                                  if (context.mounted) {
                                    Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DrillListScreen(drillGroup: drillGroup),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Close loading dialog if error occurs
                                  if (context.mounted) {
                                    Navigator.of(context, rootNavigator: true).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to load drill group details'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
