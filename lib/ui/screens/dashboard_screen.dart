import 'dart:ui';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import '../../api/api_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _userRepository = GetIt.I<UserRepository>();
  final _apiClient = GetIt.I<ApiClient>();

  User? _user;
  List<Map<String, dynamic>> _recentPracticeSessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _user = await _userRepository.getCurrentUser();
      if (_user == null) {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
        return;
      }

      await _loadRecentPracticeSessions();
    } catch (e, st) {
      developer.log(
        'Error loading dashboard data',
        name: 'DashboardScreen',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load data';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentPracticeSessions() async {
    developer.log('Loading recent practice sessions', name: 'DashboardScreen');

    try {
      if (_user == null) {
        developer.log(
          '_user is null; aborting fetch.',
          name: 'DashboardScreen',
        );
        setState(() {
          _recentPracticeSessions = const [];
          _isLoading = false;
          _error = 'User not available';
        });
        return;
      }

      final userId = _user!.id;
      developer.log(
        'Fetching recent practice sessions for userId=$userId',
        name: 'DashboardScreen',
      );

      // Only fetch the latest 3 sessions
      final sessionsResponse = await _apiClient.get(
        '/practice-sessions/users/$userId?skip=0&limit=3',
      );

      developer.log(
        'Raw sessionsResponse type: ${sessionsResponse.runtimeType}',
        name: 'DashboardScreen',
      );

      final List<Map<String, dynamic>> normalized = [];

      // Schema-aware extraction (similar to profile screen)
      if (sessionsResponse is List) {
        for (var i = 0; i < sessionsResponse.length; i++) {
          final v = sessionsResponse[i];
          if (v is Map<String, dynamic>) normalized.add(v);
        }
      } else if (sessionsResponse is Map) {
        List? itemsList;

        // Try to find the data in preferred keys
        if (sessionsResponse['data'] is List) {
          itemsList = sessionsResponse['data'] as List;
        } else if (sessionsResponse['items'] is List) {
          itemsList = sessionsResponse['items'] as List;
        } else {
          // Fallback: find the first value that is a List
          for (final k in sessionsResponse.keys) {
            final v = sessionsResponse[k];
            if (v is List) {
              itemsList = v;
              break;
            }
          }
        }

        if (itemsList != null) {
          for (var i = 0; i < itemsList.length; i++) {
            final item = itemsList[i];
            if (item is Map<String, dynamic>) normalized.add(item);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _recentPracticeSessions = normalized;
        _isLoading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log(
        'Error loading recent practice sessions',
        name: 'DashboardScreen',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load recent sessions';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.background,
              colorScheme.background,
              colorScheme.secondary.withOpacity(0.05),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back!',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'August 30, 2025',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onBackground.withOpacity(
                                    0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _CircularIconButton(
                            icon: Icons.notifications_outlined,
                            onTap: () {
                              // Handle notifications
                            },
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _ProgressCard(
                        colorScheme: colorScheme,
                        practiceSessions: _recentPracticeSessions,
                        isLoading: _isLoading,
                        hasError: _error != null,
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // View all actions
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Cards
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _ActionCard(
                        title: 'Practice',
                        subtitle: 'Improve your skills',
                        icon: Icons.sports_cricket,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withBlue(
                              colorScheme.primary.blue + 20,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          // Navigate to practice
                          Navigator.pushNamed(context, '/practice');
                        },
                      ),
                      _ActionCard(
                        title: 'View Stats',
                        subtitle: 'Track your progress',
                        icon: Icons.bar_chart,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.secondary,
                            colorScheme.secondary.withBlue(
                              colorScheme.secondary.blue + 20,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          // Navigate to stats
                        },
                      ),
                      _ActionCard(
                        title: 'Challenges',
                        subtitle: 'Test your skills',
                        icon: Icons.emoji_events,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.tertiary,
                            colorScheme.tertiary.withBlue(
                              colorScheme.tertiary.blue + 20,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          // Navigate to challenges
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Activity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // View history
                        },
                        child: Text(
                          'View History',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Activity Items
              _isLoading
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : _error != null
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Unable to load sessions',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadRecentPracticeSessions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _recentPracticeSessions.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.sports_cricket_outlined,
                                color: colorScheme.primary.withOpacity(0.5),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No practice sessions yet',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start practicing to see your sessions here',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final session = _recentPracticeSessions[index];

                        // Extract relevant data from session
                        final title =
                            session['drill_group_name'] as String? ??
                            'Practice Session';

                        // Format the timestamp
                        String formattedTime = 'Recently';
                        if (session['timestamp'] != null) {
                          try {
                            final timestamp = DateTime.parse(
                              session['timestamp'] as String,
                            );
                            final now = DateTime.now();
                            final difference = now.difference(timestamp);

                            if (difference.inMinutes < 60) {
                              formattedTime =
                                  '${difference.inMinutes} mins ago';
                            } else if (difference.inHours < 24) {
                              formattedTime = '${difference.inHours} hours ago';
                            } else {
                              formattedTime = DateFormat(
                                'MMM d',
                              ).format(timestamp);
                            }
                          } catch (e) {
                            developer.log(
                              'Error parsing timestamp: $e',
                              name: 'DashboardScreen',
                            );
                          }
                        }

                        // Calculate score and shots
                        int totalShots = 0;
                        double totalAccuracy = 0;
                        int drillCount = 0;

                        if (session['drills'] is List) {
                          final drills = session['drills'] as List;
                          drillCount = drills.length;

                          for (final drill in drills) {
                            if (drill is Map<String, dynamic>) {
                              final shots = drill['shots'] as int? ?? 0;
                              final accuracy = drill['accuracy'] as num? ?? 0;

                              totalShots += shots;
                              totalAccuracy += accuracy.toDouble();
                            }
                          }
                        }

                        final averageAccuracy = drillCount > 0
                            ? (totalAccuracy / drillCount).toStringAsFixed(0)
                            : '0';

                        return _ActivityItem(
                          title: title,
                          time: formattedTime,
                          score: '$averageAccuracy%',
                          shots: totalShots.toString(),
                          colorScheme: colorScheme,
                          index: index,
                          onTap: () {
                            // Navigate to session details
                            if (session['id'] != null) {
                              // TODO: Navigate to session details screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Viewing session details: ${session['id']}',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      }, childCount: _recentPracticeSessions.length),
                    ),

              // Upcoming Events
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming Events',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // View all events
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Event Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _EventCard(colorScheme: colorScheme),
                ),
              ),

              // Bottom Padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _CircularIconButton({
    required this.icon,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: colorScheme.primary, size: 24),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final List<Map<String, dynamic>> practiceSessions;
  final bool isLoading;
  final bool hasError;

  const _ProgressCard({
    required this.colorScheme,
    required this.practiceSessions,
    required this.isLoading,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate stats from practice sessions
    double totalHours = 0;
    int totalShots = 0;
    double averageAccuracy = 0;
    bool hasStats = false;

    if (!isLoading && !hasError && practiceSessions.isNotEmpty) {
      int sessionCount = 0;
      double totalAccuracy = 0;

      for (final session in practiceSessions) {
        // Calculate total duration in hours
        if (session['total_duration'] != null) {
          final durationMinutes = session['total_duration'] as int? ?? 0;
          totalHours += durationMinutes / 60;
        }

        // Calculate shots and accuracy
        if (session['drills'] is List) {
          final drills = session['drills'] as List;
          for (final drill in drills) {
            if (drill is Map<String, dynamic>) {
              final shots = drill['shots'] as int? ?? 0;
              final accuracy = drill['accuracy'] as num? ?? 0;

              totalShots += shots;
              if (shots > 0) {
                totalAccuracy += accuracy.toDouble();
                sessionCount++;
              }
            }
          }
        }
      }

      if (sessionCount > 0) {
        averageAccuracy = totalAccuracy / sessionCount;
        hasStats = true;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withBlue(colorScheme.primary.blue + 30),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isLoading
          ? _buildLoadingView(theme)
          : hasError
          ? _buildErrorView(theme)
          : !hasStats
          ? _buildEmptyView(theme, context)
          : _buildStatsView(theme, totalHours, totalShots, averageAccuracy),
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your progress...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              'Unable to load your progress',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Progress',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.sports_cricket_outlined,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'No practice sessions yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start practicing to track your progress',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pushNamed(context, '/practice');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Practice'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsView(
    ThemeData theme,
    double totalHours,
    int totalShots,
    double averageAccuracy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Progress',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    '${averageAccuracy.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: averageAccuracy / 100,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          minHeight: 8,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ProgressStat(
              icon: Icons.timer_outlined,
              value: totalHours.toStringAsFixed(1),
              label: 'Hours',
              color: Colors.white,
            ),
            _ProgressStat(
              icon: Icons.sports_cricket,
              value: totalShots.toString(),
              label: 'Shots',
              color: Colors.white,
            ),
            _ProgressStat(
              icon: Icons.insights,
              value: '${averageAccuracy.toStringAsFixed(0)}%',
              label: 'Accuracy',
              color: Colors.white,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ProgressStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final String score;
  final String shots;
  final ColorScheme colorScheme;
  final int index;
  final VoidCallback? onTap;

  const _ActivityItem({
    required this.title,
    required this.time,
    required this.score,
    required this.shots,
    required this.colorScheme,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 70,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              time,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _ActivityStat(
                              label: 'Score',
                              value: score,
                              color: colors[index % colors.length],
                            ),
                            const SizedBox(width: 24),
                            _ActivityStat(
                              label: 'Shots',
                              value: shots,
                              color: colors[index % colors.length],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: colorScheme.onSurface.withOpacity(0.3),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ActivityStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EventCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface.withOpacity(0.8),
                  colorScheme.surface.withOpacity(0.9),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.event, color: colorScheme.secondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Regional Tournament',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'September 15, 2025 • 10:00 AM',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Upcoming',
                        style: TextStyle(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Join the regional tournament to showcase your skills and compete with other players.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // View details
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.secondary,
                          side: BorderSide(color: colorScheme.secondary),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          // Register
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Register Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
