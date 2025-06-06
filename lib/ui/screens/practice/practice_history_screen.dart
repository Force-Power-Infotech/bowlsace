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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sports_cricket,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.drill?.name ?? 'Unknown Drill',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        dateFormat.format(session.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  context,
                  'Drill Group',
                  session.drillGroup?.name ?? 'Unknown Group',
                ),
                _buildInfoItem(
                  context,
                  'Difficulty',
                  _getDifficultyText(
                    session.drill?.difficulty != null
                        ? session.drill!.difficulty.toInt()
                        : 0,
                  ),
                ),
                _buildInfoItem(
                  context,
                  'Duration',
                  '${session.drill?.durationMinutes ?? 0} min',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
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
