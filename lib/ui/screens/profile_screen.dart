import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import '../../utils/navigation_service.dart';
import '../../api/api_client.dart';

import 'profile/widgets/common/common_widgets.dart';
import 'profile/widgets/common/sliver_app_bar_delegate.dart';
import 'profile/widgets/header_card.dart';
import 'profile/widgets/profile_tab/glass_card.dart';
import 'profile/widgets/profile_tab/info_tile.dart';
import 'profile/widgets/profile_tab/action_row.dart';
import 'profile/widgets/practice_session/practice_session_card.dart';

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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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
      await Future.wait([_loadProfile(), _loadPracticeSessions()]);
    } catch (e, st) {
      developer.log(
        'Error loading user data',
        name: 'ProfileScreen',
        error: e,
        stackTrace: st,
      );
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
        _userDetails = userResponse as Map<String, dynamic>;
        _isLoadingProfile = false;
        _profileError = null;
      });
    } catch (e, st) {
      developer.log(
        'Error loading profile details',
        name: 'ProfileScreen',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _profileError = 'Failed to load profile';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadPracticeSessions() async {
    developer.log('Starting _loadPracticeSessions()', name: 'ProfileScreen');

    try {
      if (_user == null) {
        developer.log('_user is null; aborting fetch.', name: 'ProfileScreen');
        setState(() {
          _practiceSessions = const [];
          _isLoadingSessions = false;
          _sessionsError = 'User not available';
        });
        return;
      }

      final userId = _user!.id;
      developer.log(
        'Fetching practice sessions for userId=$userId',
        name: 'ProfileScreen',
      );

      final sessionsResponse = await _apiClient.get(
        '/practice-sessions/users/$userId?skip=0&limit=50',
      );

      developer.log(
        'Raw sessionsResponse type: ${sessionsResponse.runtimeType}',
        name: 'ProfileScreen',
      );

      // Pretty print full JSON
      try {
        final pretty = const JsonEncoder.withIndent(
          '  ',
        ).convert(sessionsResponse);
        developer.log('Full sessionsResponse:\n$pretty', name: 'ProfileScreen');
      } catch (err) {
        developer.log('Pretty print failed: $err', name: 'ProfileScreen');
      }

      final List<Map<String, dynamic>> normalized = [];

      // ------- Schema-aware extraction -------
      if (sessionsResponse is List) {
        developer.log(
          'sessionsResponse is a List (length: ${sessionsResponse.length})',
          name: 'ProfileScreen',
        );
        for (var i = 0; i < sessionsResponse.length; i++) {
          final v = sessionsResponse[i];
          developer.log('List[$i] → ${v.runtimeType}', name: 'ProfileScreen');
          if (v is Map<String, dynamic>) normalized.add(v);
        }
      } else if (sessionsResponse is Map) {
        developer.log(
          'sessionsResponse is a Map with keys: ${sessionsResponse.keys.toList()}',
          name: 'ProfileScreen',
        );

        List? itemsList;

        // Preferred keys in order
        if (sessionsResponse['data'] is List) {
          itemsList = sessionsResponse['data'] as List;
          developer.log(
            'Using "data" list (length: ${itemsList.length})',
            name: 'ProfileScreen',
          );
        } else if (sessionsResponse['items'] is List) {
          itemsList = sessionsResponse['items'] as List;
          developer.log(
            'Using "items" list (length: ${itemsList.length})',
            name: 'ProfileScreen',
          );
        } else {
          // Fallback: find the first value that is a List
          for (final k in sessionsResponse.keys) {
            final v = sessionsResponse[k];
            if (v is List) {
              itemsList = v;
              developer.log(
                'Fallback: using list at key "$k" (length: ${itemsList.length})',
                name: 'ProfileScreen',
              );
              break;
            }
          }
        }

        if (itemsList == null) {
          developer.log(
            'No list field found (expected "data" or "items").',
            name: 'ProfileScreen',
          );
        } else {
          for (var i = 0; i < itemsList.length; i++) {
            final item = itemsList[i];
            developer.log(
              'Item $i → ${item.runtimeType}',
              name: 'ProfileScreen',
            );
            if (item is Map<String, dynamic>) normalized.add(item);
          }
        }
      } else {
        developer.log(
          'Unexpected response type: ${sessionsResponse.runtimeType}',
          name: 'ProfileScreen',
        );
      }
      // --------------------------------------

      // Optional: log a sample of the first normalized item
      if (normalized.isNotEmpty) {
        final samplePretty = const JsonEncoder.withIndent(
          '  ',
        ).convert(normalized.first);
        developer.log(
          'First normalized item sample:\n$samplePretty',
          name: 'ProfileScreen',
        );
      }

      if (!mounted) return;
      setState(() {
        _practiceSessions = normalized;
        _isLoadingSessions = false;
        _sessionsError = null;
      });

      developer.log(
        'Successfully normalized ${normalized.length} sessions',
        name: 'ProfileScreen',
      );
    } catch (e, st) {
      developer.log(
        'Error loading practice sessions',
        name: 'ProfileScreen',
        error: e,
        stackTrace: st,
      );
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
    return Scaffold(
      body: SafeArea(
        child: (_isLoadingProfile && _isLoadingSessions)
            ? const Center(child: CircularProgressIndicator())
            : DefaultTabController(
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: HeaderCard(
                        fullName: _userDetails?['full_name'] ?? 'User',
                        email: _userDetails?['email'] as String?,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
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
                            ? const CenteredLoader()
                            : _profileError != null
                            ? ErrorView(
                                message: _profileError!,
                                onRetry: _loadProfile,
                              )
                            : SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    GlassCard(
                                      child: Column(
                                        children: [
                                          InfoTile(
                                            icon: Icons.phone_outlined,
                                            title: 'Phone',
                                            value:
                                                _userDetails?['phone_number'] ??
                                                'Not set',
                                          ),
                                          const TDivider(),
                                          InfoTile(
                                            icon: Icons.person_outline,
                                            title: 'Username',
                                            value:
                                                _userDetails?['username'] ??
                                                'Not set',
                                          ),
                                          const TDivider(),
                                          InfoTile(
                                            icon: Icons.numbers_outlined,
                                            title: 'User ID',
                                            value:
                                                _userDetails?['id']
                                                    ?.toString() ??
                                                'N/A',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ActionRow(onLogout: _handleLogout),
                                  ],
                                ),
                              ),
                      ),

                      // -------- Practice Sessions Tab --------
                      RefreshIndicator(
                        onRefresh: _loadPracticeSessions,
                        child: _isLoadingSessions
                            ? const CenteredLoader()
                            : _sessionsError != null
                            ? ErrorView(
                                message: _sessionsError!,
                                onRetry: _loadPracticeSessions,
                              )
                            : (_practiceSessions.isEmpty)
                            ? const EmptyState(
                                title: 'No practice sessions yet',
                                subtitle:
                                    'Your recorded sessions will appear here.',
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: _practiceSessions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return PracticeSessionCard(
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

