import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import '../../utils/navigation_service.dart';
import '../../api/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Sticky TabBar for NestedScrollView
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepository = GetIt.I<UserRepository>();
  final _apiClient = GetIt.I<ApiClient>();

  User? _user;
  Map<String, dynamic>? _userDetails;
  List<Map<String, dynamic>> _practiceSessions = [];

  bool _isLoadingProfile = true;
  bool _isLoadingSessions = true;
  String? _profileError;
  String? _sessionsError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingProfile = true;
      _isLoadingSessions = true;
      _profileError = null;
      _sessionsError = null;
    });

    try {
      _user = await _userRepository.getCurrentUser();
      if (_user == null) {
        setState(() {
          _profileError = 'User not found';
          _sessionsError = 'User not found';
          _isLoadingProfile = false;
          _isLoadingSessions = false;
        });
        return;
      }

      // Load both in parallel
      await Future.wait([
        _loadProfile(),
        _loadPracticeSessions(),
      ]);
    } catch (e, st) {
      developer.log('Error loading user data',
          name: 'ProfileScreen', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _profileError = 'Unable to load user data';
        _sessionsError = 'Unable to load user data';
        _isLoadingProfile = false;
        _isLoadingSessions = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _user!.id; // safe because set only when _user != null
      final userResponse = await _apiClient.get('/users/$userId');

      if (!mounted) return;
      setState(() {
        // Defensive cast
        _userDetails = (userResponse is Map<String, dynamic>)
            ? userResponse
            : <String, dynamic>{};
        _isLoadingProfile = false;
        _profileError = null;
      });
    } catch (e, st) {
      developer.log('Error loading profile details',
          name: 'ProfileScreen', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _profileError = 'Failed to load profile';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadPracticeSessions() async {
    try {
      final userId = _user!.id;
      final sessionsResponse = await _apiClient.get(
        '/api/v1/practice-sessions/users/$userId?skip=0&limit=50',
      );

      // Normalize to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> normalized = [];
      if (sessionsResponse is List) {
        for (final entry in sessionsResponse.entries) {
  final key = entry.key;
  final value = entry.value;
  print('Key: $key, Value: $value');
}

      } else if (sessionsResponse is Map<String, dynamic> &&
          sessionsResponse['items'] is List) {
        for (final item in (sessionsResponse['items'] as List)) {
          if (item is Map<String, dynamic>) normalized.add(item);
        }
      }

      if (!mounted) return;
      setState(() {
        _practiceSessions = normalized;
        _isLoadingSessions = false;
        _sessionsError = null;
      });
    } catch (e, st) {
      developer.log('Error loading practice sessions',
          name: 'ProfileScreen', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _sessionsError = 'Failed to load practice sessions';
        _isLoadingSessions = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _userRepository.clearUser();
      GetIt.I<NavigationService>().navigateToAndClear('/login');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final headline = Theme.of(context)
        .textTheme
        .headlineSmall
        ?.copyWith(fontWeight: FontWeight.w800);

    return Scaffold(
      body: SafeArea(
        child: (_isLoadingProfile && _isLoadingSessions)
            ? const Center(child: CircularProgressIndicator())
            : DefaultTabController(
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: _HeaderCard(
                        fullName: _userDetails?['full_name'] ?? 'User',
                        email: _userDetails?['email'] as String?,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: 'Profile'),
                            Tab(text: 'Practice Sessions'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    children: [
                      // -------- Profile Tab --------
                      RefreshIndicator(
                        onRefresh: _loadProfile,
                        child: _isLoadingProfile
                            ? const _CenteredLoader()
                            : _profileError != null
                                ? _ErrorView(
                                    message: _profileError!,
                                    onRetry: _loadProfile,
                                  )
                                : SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        _GlassCard(
                                          child: Column(
                                            children: [
                                              _InfoTile(
                                                icon: Icons.phone_outlined,
                                                title: 'Phone',
                                                value:
                                                    _userDetails?['phone_number'] ??
                                                        'Not set',
                                              ),
                                              const _TDivider(),
                                              _InfoTile(
                                                icon: Icons.person_outline,
                                                title: 'Username',
                                                value:
                                                    _userDetails?['username'] ??
                                                        'Not set',
                                              ),
                                              const _TDivider(),
                                              _InfoTile(
                                                icon: Icons.numbers_outlined,
                                                title: 'User ID',
                                                value:
                                                    _userDetails?['id']?.toString() ??
                                                        'N/A',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _ActionRow(
                                          onLogout: _handleLogout,
                                        ),
                                      ],
                                    ),
                                  ),
                      ),

                      // -------- Practice Sessions Tab --------
                      RefreshIndicator(
                        onRefresh: _loadPracticeSessions,
                        child: _isLoadingSessions
                            ? const _CenteredLoader()
                            : _sessionsError != null
                                ? _ErrorView(
                                    message: _sessionsError!,
                                    onRetry: _loadPracticeSessions,
                                  )
                                : (_practiceSessions.isEmpty)
                                    ? const _EmptyState(
                                        title: 'No practice sessions yet',
                                        subtitle:
                                            'Your recorded sessions will appear here.',
                                      )
                                    : ListView.separated(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _practiceSessions.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          return _PracticeSessionCard(
                                            session: _practiceSessions[index],
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// ---------- UI Bits ----------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.fullName, this.email});
  final String fullName;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.12),
            scheme.primaryContainer.withOpacity(0.24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: scheme.primary.withOpacity(0.12),
            child: Icon(Icons.person_outline, size: 42, color: scheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              runSpacing: 4,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (email != null)
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: Colors.grey.withOpacity(0.15));
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _TDivider extends StatelessWidget {
  const _TDivider();
  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.grey.withOpacity(0.2), height: 20);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PracticeSessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  const _PracticeSessionCard({required this.session});

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    final dateTime = DateTime.tryParse(dateTimeStr);
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM d, y • h:mm a').format(dateTime.toLocal());
    }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final drillGroupName =
        (session['drill_group_name'] as String?) ?? 'Untitled Session';
    final totalShots = (session['total_shots'] ?? 0).toString();
    final durationSecs = (session['total_duration_seconds'] ?? 0).toString();
    final avgAcc = session['avg_accuracy']?.toString() ?? '0';
    final drills = (session['drills'] is List) ? session['drills'] as List : [];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    drillGroupName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalShots shots',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.timer_outlined,
                    value: '${durationSecs}s',
                    label: 'Duration',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.timeline,
                    value: '$avgAcc%',
                    label: 'Accuracy',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.sports,
                    value: '${drills.length}',
                    label: 'Drills',
                  ),
                ),
              ],
            ),

            if (drills.isNotEmpty) ...[
              const _TDivider(),
              Text(
                'Drills',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...List.generate(drills.length, (index) {
                final drill = drills[index] as Map<String, dynamic>? ?? {};
                final name = (drill['name'] ?? 'Drill').toString();
                final shots = (drill['shots'] ?? 0).toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text('$shots shots',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Started: ${_formatDateTime(session['started_at'] as String?)}',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: scheme.onSurfaceVariant.withOpacity(0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
