import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di/service_locator.dart';
import '../../../models/user.dart';
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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user data
      final user = await _authRepository.getCurrentUser();
      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).setUser(user);

      // Load recent practice sessions
      final sessions = await _practiceRepository.getRecentSessions(limit: 5);
      if (!mounted) return;
      Provider.of<PracticeProvider>(
        context,
        listen: false,
      ).setSessions(sessions);
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

  void _startNewPractice() {
    Navigator.of(context).pushNamed('/practice/new');
  }

  void _viewAllPractices() {
    Navigator.of(context).pushNamed('/practice/list');
  }

  void _viewAllChallenges() {
    Navigator.of(context).pushNamed('/challenge/list');
  }

  void _logout() async {
    setState(() {
      _isLoading = true;
    });

    await _authRepository.logout();

    // Clear all providers
    if (!mounted) return;
    Provider.of<UserProvider>(context, listen: false).clearUser();
    Provider.of<PracticeProvider>(context, listen: false).clearSessions();

    // Navigate to login
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Access the user data from provider
    final userProvider = Provider.of<UserProvider>(context);
    final practiceProvider = Provider.of<PracticeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
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
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User greeting
                    if (userProvider.user != null)
                      Text(
                        'Welcome, ${userProvider.user!.firstName ?? userProvider.user!.username}!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    const SizedBox(height: 24),

                    // Quick action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _QuickActionButton(
                          icon: Icons.fitness_center,
                          label: 'New Practice',
                          onTap: _startNewPractice,
                        ),
                        _QuickActionButton(
                          icon: Icons.emoji_events,
                          label: 'Challenges',
                          onTap: _viewAllChallenges,
                        ),
                        _QuickActionButton(
                          icon: Icons.history,
                          label: 'History',
                          onTap: _viewAllPractices,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Recent practice sessions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Practice Sessions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: _viewAllPractices,
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // List of recent sessions
                    practiceProvider.sessions.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text('No recent practice sessions'),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: practiceProvider.sessions.length,
                            itemBuilder: (context, index) {
                              final session = practiceProvider.sessions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(session.name),
                                  subtitle: Text(
                                    '${session.durationMinutes} mins • ${session.location ?? 'No location'}',
                                  ),
                                  trailing: Text(
                                    _formatDate(session.createdAt),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  onTap: () => Navigator.of(context).pushNamed(
                                    '/practice/details',
                                    arguments: session,
                                  ),
                                ),
                              );
                            },
                          ),

                    const SizedBox(height: 32),

                    // Add more sections as needed
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewPractice,
        icon: const Icon(Icons.add),
        label: const Text('New Practice'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
