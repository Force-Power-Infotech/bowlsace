import 'package:flutter/material.dart';
import '../../models/meta_drill_group.dart';
import '../../models/drill_group.dart';
import '../../services/drill_service.dart';
import 'meta_drill_group_detail_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final DrillService _drillService = DrillService();
  final TextEditingController _searchController = TextEditingController();
  List<MetaDrillGroup> _metaDrillGroups = [];
  List<DrillGroup> _drillGroups = [];
  List<MetaDrillGroup> _filteredMetaDrillGroups = [];
  List<DrillGroup> _filteredDrillGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final metaDrillGroups = await _drillService.getMetaDrillGroups();
      final drillGroups = await _drillService.getDrillGroups();
      setState(() {
        _metaDrillGroups = metaDrillGroups;
        _drillGroups = drillGroups;
        _filteredMetaDrillGroups = metaDrillGroups;
        _filteredDrillGroups = drillGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: ${e.toString()}')),
      );
    }
  }

  void _filterData(String query) {
    setState(() {
      _filteredMetaDrillGroups = _metaDrillGroups
          .where(
            (group) =>
                group.name.toLowerCase().contains(query.toLowerCase()) ||
                group.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      _filteredDrillGroups = _drillGroups
          .where(
            (group) =>
                group.name.toLowerCase().contains(query.toLowerCase()) ||
                group.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.background,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterData,
            decoration: InputDecoration(
              hintText: 'Search drills...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        toolbarHeight: 70,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta Drill Groups Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Meta Drill Groups',
                          style: theme.textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            // Handle view all
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: _filteredMetaDrillGroups.isEmpty
                          ? const Center(
                              child: Text('No meta drill groups found'),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filteredMetaDrillGroups.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final group = _filteredMetaDrillGroups[index];
                                return _ModernCard(
                                  title: group.name,
                                  subtitle: group.description,
                                  icon: Icons.category,
                                  color: Colors.blueAccent,
                                  imageUrl: group.imageUrl,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MetaDrillGroupDetailScreen(
                                              id: group.id,
                                            ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 32),
                    // Drill Groups Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Drill Groups', style: theme.textTheme.titleLarge),
                        TextButton(
                          onPressed: () {
                            // Handle view all
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _filteredDrillGroups.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No drill groups found'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredDrillGroups.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final group = _filteredDrillGroups[index];
                              return _DrillGroupCard(
                                drillGroup: group,
                                onTap: () {
                                  // Handle drill group tap
                                },
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _ModernCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              SizedBox(
                height: 80,
                width: double.infinity,
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: color.withOpacity(0.2),
                    child: Icon(icon, color: color),
                  ),
                ),
              )
            else
              Container(
                height: 80,
                width: double.infinity,
                color: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 32),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrillGroupCard extends StatelessWidget {
  final DrillGroup drillGroup;
  final VoidCallback onTap;

  const _DrillGroupCard({required this.drillGroup, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 100,
                child: Image.network(
                  drillGroup.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.sports, color: theme.colorScheme.primary),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drillGroup.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drillGroup.description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Difficulty: ${drillGroup.difficulty}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            drillGroup.isPublic ? Icons.public : Icons.lock,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            drillGroup.isPublic ? 'Public' : 'Private',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
