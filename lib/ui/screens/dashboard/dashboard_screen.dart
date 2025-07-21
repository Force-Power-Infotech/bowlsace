import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ui/screens/search/search_screen.dart';
import '../../../di/service_locator.dart';

import '../../../providers/user_provider.dart';
import '../../../providers/practice_provider.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/practice_repository.dart';
import '../../../api/api_error_handler.dart';
import '../../../models/practice_session.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Removed unused _showSearch and _searchController
  bool _isLoading = true;
  String? _errorMessage;

  final AuthRepository _authRepository = getIt<AuthRepository>();
  final PracticeRepository _practiceRepository = getIt<PracticeRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void initState() {
    super.initState();
    // _loadDashboardData(); // API call commented out for UI preview
    setState(() {
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _loadDashboardData() async {
    // API/data loading commented out for UI preview
    setState(() {
      _isLoading = false;
      _errorMessage = null;
    });
    // try {
    //   await Future.wait([_loadUserData(), _loadPracticeSessions()]);
    // } catch (e) {
    //   _errorHandler.handleError(e);
    //   if (!mounted) return;
    //   setState(() {
    //     _errorMessage = 'Failed to load dashboard data';
    //   });
    // } finally {
    //   if (mounted) {
    //     setState(() {
    //       _isLoading = false;
    //     });
    //   }
    // }
  }

  Future<void> _loadUserData() async {
    // API call commented out for UI preview
    // if (!mounted) return;
    // final user = await _authRepository.getCurrentUser();
    // if (!mounted) return;
    // Provider.of<UserProvider>(context, listen: false).setUser(user);
  }

  Future<void> _loadPracticeSessions() async {
    // API call commented out for UI preview
    // if (!mounted) return;
    // final sessions = await _practiceRepository.getRecentSessions(limit: 5);
    // if (!mounted) return;
    // Provider.of<PracticeProvider>(context, listen: false).setSessions(sessions);
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
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        children: [
          const SizedBox(height: 24),
          // Header row: user name (or search bar), search icon, logout
          if (userProvider.user != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    userProvider.user?.fullName ??
                        userProvider.user!.username ??
                        'Bowler',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Search icon button (top right)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          // Stats card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Stats',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.auto_graph_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.fitness_center,
                      value: practiceProvider.sessions.length.toString(),
                      label: 'Sessions',
                      color: theme.colorScheme.primary,
                    ),
                    _StatItem(
                      icon: Icons.timer,
                      value: '${_calculateTotalMinutes(practiceProvider.sessions)}',
                      label: 'Minutes',
                      color: theme.colorScheme.primary,
                    ),
                    _StatItem(
                      icon: Icons.emoji_events,
                      value: '0',
                      label: 'Completed',
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Quick actions card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    onTap: _startNewPractice,
                    icon: Icons.play_circle_fill_rounded,
                    label: 'New Practice',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    onTap: _viewAllChallenges,
                    icon: Icons.emoji_events_rounded,
                    label: 'Challenges',
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Recent Sessions title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Sessions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _viewAllPractices,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Recent Sessions list
          if (practiceProvider.sessions.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_cricket,
                    size: 48,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent practice sessions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _startNewPractice,
                    icon: const Icon(Icons.add),
                    label: const Text('Start your first session'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (final session in practiceProvider.sessions)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).pushNamed(
                          '/practice/details',
                          arguments: session,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Session type icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.sports_cricket,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Session details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${session.durationMinutes} mins',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          session.location ?? 'No location',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Date and arrow
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatDate(session.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _calculateTotalMinutes(List<Session> sessions) {
    return sessions.fold<int>(0, (sum, session) => sum + session.durationMinutes);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
