import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../di/service_locator.dart';
import '../../../models/practice_model.dart';
import '../../../providers/practice_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../api/api_error_handler.dart';

class PracticeHistoryScreen extends StatefulWidget {
  const PracticeHistoryScreen({super.key});

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  final _errorHandler = getIt<ApiErrorHandler>();
  bool _isInitialized = false;

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  IconData _getDrillTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'speed':
        return Icons.speed;
      case 'accuracy':
        return Icons.gps_fixed;
      case 'power':
        return Icons.fitness_center;
      default:
        return Icons.sports_cricket;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is safer than using initState for Provider operations
    if (!_isInitialized) {
      _loadPracticeSessions();
      _isInitialized = true;
    }
  }

  Future<void> _loadPracticeSessions() async {
    final userProvider = getIt<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      _errorHandler.handleError(Exception('User is not authenticated'));
      return;
    }

    final practiceProvider = getIt<PracticeProvider>();

    try {
      print('Fetching practice sessions for user ID: ${user.id}');
      await practiceProvider.getUserPracticeSessions(
        userId: user.id,
        skip: 0,
        limit: 100,
      );
    } catch (e) {
      print('Error in practice history screen: $e');
      _errorHandler.handleError(e);
    }
  }

  Future<void> _refreshSessions() async {
    final userProvider = getIt<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      _errorHandler.handleError(Exception('User is not authenticated'));
      return;
    }

    final practiceProvider = getIt<PracticeProvider>();

    try {
      await practiceProvider.getUserPracticeSessions(
        userId: user.id,
        skip: 0,
        limit: 100,
      );
    } catch (e) {
      _errorHandler.handleError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshSessions(),
          ),
        ],
      ),
      body: Consumer<PracticeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load practice sessions',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _refreshSessions(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final sessions = provider.practiceSessions;

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_cricket,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No practice sessions yet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new practice session to see your history',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshSessions,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildSessionCard(context, session);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, PracticeSession session) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final difficultyLevel = (session.drill?.difficulty ?? 0).toInt();
    final difficultyColor = _getDifficultyColor(difficultyLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to session details
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getDrillTypeIcon(session.drill?.drillType),
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.drill?.name ?? 'Unknown Drill',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(session.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: difficultyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: difficultyColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getDifficultyText(difficultyLevel),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: difficultyColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    context,
                    Icons.group_work_outlined,
                    'Group',
                    session.drillGroup?.name ?? 'Unknown',
                  ),
                  _buildInfoItem(
                    context,
                    Icons.timer_outlined,
                    'Duration',
                    '${session.drill?.durationMinutes ?? 0} min',
                  ),
                  _buildInfoItem(
                    context,
                    Icons.track_changes_outlined,
                    'Target',
                    '${session.drill?.targetScore ?? 0} points',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getDifficultyText(int level) {
    if (level <= 1) return 'Easy';
    if (level <= 2) return 'Moderate';
    if (level <= 3) return 'Challenging';
    if (level <= 4) return 'Difficult';
    return 'Expert';
  }
}
