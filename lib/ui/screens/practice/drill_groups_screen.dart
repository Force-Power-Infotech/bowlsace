import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../ui/screens/search/search_screen.dart';
import '../../../models/drill_group.dart';
import '../../../providers/practice_provider.dart';
import '../../../providers/user_provider.dart';
import 'drill_list_screen.dart';
import 'create_drill_group_screen.dart';

class DrillGroupsScreen extends StatefulWidget {
  const DrillGroupsScreen({super.key});

  @override
  State<DrillGroupsScreen> createState() => _DrillGroupsScreenState();
}

class _DrillGroupsScreenState extends State<DrillGroupsScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDrillGroups();
    });
  }

  Future<void> _loadDrillGroups() async {
    if (!mounted) return;
    final provider = Provider.of<PracticeProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Load drill groups
    await provider.getDrillGroups();

    // Load practice sessions for the current user
    if (userProvider.user != null) {
      await provider.getUserPracticeSessions(userId: userProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PracticeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final drillGroups = provider.drillGroups;
    final practiceSessions = provider.practiceSessions;
    final theme = Theme.of(context);
    final isLoading = provider.isLoading;
    final error = provider.error;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _loadDrillGroups,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Modern app bar with animated effects
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: theme.primaryColor,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Practice History',
                  onPressed: () {
                    Navigator.pushNamed(context, '/practice/history');
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Practice Drills',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Master your bowling techniques',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/practicebg.png',
                      fit: BoxFit.cover,
                    ),
                    // Gradient overlay
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            theme.primaryColor.withOpacity(0.3),
                            theme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    // Pattern overlay
                    Positioned.fill(
                      child: CustomPaint(painter: GridPainter(opacity: 0.1)),
                    ),
                  ],
                ),
                stretchModes: const [
                  StretchMode.fadeTitle,
                ],
              ),
            ),

            if (error != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          error,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        onPressed: _loadDrillGroups,
                      ),
                    ],
                  ),
                ),
              ),

            if (isLoading && drillGroups.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (drillGroups.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sports_cricket,
                          size: 64,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Drill Groups Yet',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pull down to refresh or create a new group',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Featured Groups with search bar above
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar above heading
                      SizedBox(
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchScreen(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[900] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.search, size: 20, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Search groups...',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'List of Drills',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final featuredGroups = drillGroups
                              .where((g) => g.isPublic && (_searchQuery.isEmpty || g.name.toLowerCase().contains(_searchQuery.toLowerCase())))
                              .toList();
                          if (_searchQuery.isNotEmpty && featuredGroups.isEmpty) {
                            return Container(
                              height: 120,
                              alignment: Alignment.center,
                              child: Text(
                                'No such group found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: featuredGroups.length,
                              itemBuilder: (context, index) {
                                final group = featuredGroups[index];
                                return Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    start: index == 0 ? 0 : 16,
                                    end: index == featuredGroups.length - 1 ? 0 : 0,
                                  ),
                                  child: _FeaturedDrillGroupCard(group: group),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Practice History Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Practice History',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // List of practice sessions
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                sliver: practiceSessions.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: theme.primaryColor.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No practice history yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete a practice session to see your history',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final session = practiceSessions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.sports_cricket,
                                  color: theme.primaryColor,
                                ),
                              ),
                              title: Text(
                                session.drill?.name ?? 'Practice Session',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    session.drillGroup?.name ?? 'Unknown Group',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'MMMM d, yyyy - h:mm a',
                                    ).format(session.createdAt),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                              onTap: () {
                                // TODO: Navigate to practice session details
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Viewing details for ${session.drill?.name ?? 'Practice Session'}',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          );
                        }, childCount: practiceSessions.length),
                      ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateDrillGroupScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Group'),
        elevation: 4,
      ),
    );
  }
}

class _FeaturedDrillGroupCard extends StatelessWidget {
  final DrillGroup group;

  const _FeaturedDrillGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DrillListScreen(drillGroup: group),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image with gradient overlay
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: Icon(
                      Icons.sports_cricket,
                      size: 48,
                      color: Colors.white24,
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Level ${group.difficulty}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 36,
                    child: Text(
                      group.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
  final DrillGroup group;

  const _DrillGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DrillListScreen(drillGroup: group),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    theme.primaryColor.withOpacity(0.8),
                    theme.primaryColor,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.sports_cricket,
                      size: 36,
                      color: Colors.white24,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${group.drills.length} Drills',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 40, // Fixed height container for description
                    child: SingleChildScrollView(
                      child: Text(
                        group.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${group.difficulty}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
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

class GridPainter extends CustomPainter {
  final double opacity;

  GridPainter({this.opacity = 0.1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 0.5;

    for (var i = 0.0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (var i = 0.0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
