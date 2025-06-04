import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di/service_locator.dart';
import '../../../models/practice_session.dart';
import '../../../providers/practice_provider.dart';
import '../../../repositories/practice_repository.dart';
import '../../../api/api_error_handler.dart';

class PracticeListScreen extends StatefulWidget {
  const PracticeListScreen({super.key});

  @override
  State<PracticeListScreen> createState() => _PracticeListScreenState();
}

class _PracticeListScreenState extends State<PracticeListScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  final PracticeRepository _practiceRepository = getIt<PracticeRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreSessions();
      }
    }
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final provider = Provider.of<PracticeProvider>(context, listen: false);
      provider.setLoading(true);

      // Load practice sessions
      final sessions = await _practiceRepository.getSessions();

      if (!mounted) return;

      // Sort by date (most recent first)
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Update sessions in provider
      provider.setSessions(sessions);

      setState(() {
        _hasMoreData = sessions.length >= _pageSize;
      });
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load practice sessions';
      });
    } finally {
      if (mounted) {
        final provider = Provider.of<PracticeProvider>(context, listen: false);
        provider.setLoading(false);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreSessions() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final moreSessions = await _practiceRepository.getSessions();

      if (moreSessions.isNotEmpty) {
        final provider = Provider.of<PracticeProvider>(context, listen: false);

        // Sort by date and combine with existing sessions
        moreSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final allSessions = [...provider.sessions, ...moreSessions];

        // Update provider
        provider.setSessions(allSessions);

        setState(() {
          _currentPage = nextPage;
          _hasMoreData = moreSessions.length >= _pageSize;
        });
      } else {
        setState(() {
          _hasMoreData = false;
        });
      }
    } catch (e) {
      _errorHandler.handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _goToCreatePractice() {
    Navigator.of(context).pushNamed('/practice/new');
  }

  @override
  Widget build(BuildContext context) {
    final practiceProvider = Provider.of<PracticeProvider>(context);
    final sessions = practiceProvider.sessions;

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Sessions')),
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
                    onPressed: _loadSessions,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No practice sessions yet'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _goToCreatePractice,
                            child: const Text('Start a Practice Session'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: sessions.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == sessions.length) {
                          // Show loading indicator at the bottom when loading more
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final session = sessions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              session.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${session.durationMinutes} mins'),
                                    const SizedBox(width: 16),
                                    if (session.location != null) ...[
                                      const Icon(Icons.location_on, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          session.location!,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(session.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/practice/details',
                                arguments: session,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreatePractice,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}, ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
