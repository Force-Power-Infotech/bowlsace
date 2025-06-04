import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di/service_locator.dart';

import '../../../providers/user_provider.dart';
import '../../../providers/practice_provider.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/practice_repository.dart';
import '../../../api/api_error_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  final AuthRepository _authRepository = getIt<AuthRepository>();
  final PracticeRepository _practiceRepository = getIt<PracticeRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user data and recent practice sessions
      await Future.wait([_loadUserData(), _loadPracticeSessions()]);
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load dashboard data';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    final user = await _authRepository.getCurrentUser();
    if (!mounted) return;
    Provider.of<UserProvider>(context, listen: false).setUser(user);
  }

  Future<void> _loadPracticeSessions() async {
    if (!mounted) return;
    final sessions = await _practiceRepository.getRecentSessions(limit: 5);
    if (!mounted) return;
    Provider.of<PracticeProvider>(context, listen: false).setSessions(sessions);
  }

  void _startNewPractice() {
    Navigator.of(context).pushNamed('/practice/new');
  }

  void _viewAllPractices() {
    Navigator.of(context).pushNamed('/practice/list');
  }

  void _viewAllChallenges() {
    Navigator.of(context).pushNamed('/challenge/list');
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.logout();

      if (!mounted) return;
      // Clear all providers
      Provider.of<UserProvider>(context, listen: false).clearUser();
      Provider.of<PracticeProvider>(context, listen: false).clearSessions();

      // Navigate to login
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
    final userProvider = Provider.of<UserProvider>(context);
    final practiceProvider = Provider.of<PracticeProvider>(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Modern app bar with user info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (userProvider.user != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProvider.user!.firstName ??
                              userProvider.user!.username ??
                              'Bowler',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Quick action buttons
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _QuickActionCard(
                  icon: Icons.fitness_center,
                  label: 'Start Practice',
                  description: 'Begin a new practice session',
                  onTap: _startNewPractice,
                  color: theme.colorScheme.primary,
                ),
                _QuickActionCard(
                  icon: Icons.emoji_events,
                  label: 'Challenges',
                  description: 'View and accept challenges',
                  onTap: _viewAllChallenges,
                  color: theme.colorScheme.secondary,
                ),
                _QuickActionCard(
                  icon: Icons.history,
                  label: 'History',
                  description: 'View practice history',
                  onTap: _viewAllPractices,
                  color: theme.colorScheme.tertiary,
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
            ),
          ),

          // Recent sessions title
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Sessions', style: theme.textTheme.titleLarge),
                  TextButton(
                    onPressed: _viewAllPractices,
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
          ),

          // Recent sessions list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: practiceProvider.sessions.isEmpty
                ? SliverToBoxAdapter(
                    child: Card(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        height: 100,
                        child: const Center(
                          child: Text('No recent practice sessions'),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final session = practiceProvider.sessions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            session.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${session.durationMinutes} mins • ${session.location ?? 'No location'}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDate(session.createdAt),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed('/practice/details', arguments: session),
                        ),
                      );
                    }, childCount: practiceProvider.sessions.length),
                  ),
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
