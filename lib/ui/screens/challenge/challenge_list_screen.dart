import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di/service_locator.dart';
import '../../../models/challenge.dart';
import '../../../providers/challenge_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../repositories/challenge_repository.dart';
import '../../../api/api_error_handler.dart';

class ChallengeListScreen extends StatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  final ChallengeRepository _challengeRepository = getIt<ChallengeRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final challengeProvider = Provider.of<ChallengeProvider>(
        context,
        listen: false,
      );
      challengeProvider.setLoading(true);

      // Load all challenges
      final allChallenges = await _challengeRepository.getChallenges();
      // Load pending challenges separately
      final pendingChallenges = await _challengeRepository
          .getPendingChallenges();

      if (!mounted) return;

      challengeProvider.setChallenges(allChallenges);
      challengeProvider.setPendingChallenges(pendingChallenges);
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load challenges';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Provider.of<ChallengeProvider>(
          context,
          listen: false,
        ).setLoading(false);
      }
    }
  }

  void _goToCreateChallenge() {
    Navigator.of(context).pushNamed('/challenge/new');
  }

  void _viewChallengeDetails(Challenge challenge) {
    // Store selected challenge in provider
    Provider.of<ChallengeProvider>(
      context,
      listen: false,
    ).setSelectedChallenge(challenge);

    // Navigate to details
    Navigator.of(context).pushNamed('/challenge/details', arguments: challenge);
  }

  Future<void> _respondToChallenge(Challenge challenge, bool accept) async {
    try {
      final challengeProvider = Provider.of<ChallengeProvider>(
        context,
        listen: false,
      );
      challengeProvider.setLoading(true);

      Challenge updatedChallenge;
      if (accept) {
        updatedChallenge = await _challengeRepository.acceptChallenge(
          challenge.id,
        );
      } else {
        updatedChallenge = await _challengeRepository.declineChallenge(
          challenge.id,
        );
      }

      if (!mounted) return;

      // Update the challenge in the provider
      challengeProvider.updateChallenge(updatedChallenge);
      challengeProvider.setLoading(false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Challenge ${accept ? 'accepted' : 'declined'}'),
          duration: const Duration(seconds: 2),
        ),
      );

      // If accepted, go to challenge details
      if (accept) {
        _viewChallengeDetails(updatedChallenge);
      }
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to respond to challenge'),
          duration: Duration(seconds: 2),
        ),
      );

      Provider.of<ChallengeProvider>(context, listen: false).setLoading(false);
    }
  }

  Widget _buildChallengeItem(Challenge challenge) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.user?.id ?? 0;

    // Determine if the current user is the sender or recipient
    final isSender = challenge.senderId == currentUserId;
    final otherPersonName = isSender
        ? challenge.recipientName
        : challenge.senderName;

    // Determine challenge status text and color
    String statusText;
    Color statusColor;

    switch (challenge.status) {
      case 'PENDING':
        statusText = isSender ? 'Awaiting Response' : 'Response Required';
        statusColor = Colors.orange;
        break;
      case 'ACCEPTED':
        statusText = 'In Progress';
        statusColor = Colors.blue;
        break;
      case 'COMPLETED':
        final isWinner = challenge.winnerUserId == currentUserId;
        statusText = isWinner ? 'Won' : 'Lost';
        statusColor = isWinner ? Colors.green : Colors.red;
        break;
      case 'DECLINED':
        statusText = 'Declined';
        statusColor = Colors.grey;
        break;
      default:
        statusText = challenge.status;
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(
              isSender
                  ? 'Challenge to ${challenge.recipientName}'
                  : 'Challenge from ${challenge.senderName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (challenge.drillName != null)
                  Text('Drill: ${challenge.drillName!}'),
                const SizedBox(height: 4),
                if (challenge.completionDeadline != null)
                  Text(
                    'Deadline: ${_formatDate(challenge.completionDeadline!)}',
                  ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${_formatDate(challenge.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(statusText, style: TextStyle(color: statusColor)),
            ),
            onTap: () => _viewChallengeDetails(challenge),
          ),

          // Response buttons for pending challenges that are received (not sent)
          if (challenge.status == 'PENDING' && !isSender)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToChallenge(challenge, false),
                      child: const Text('DECLINE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondToChallenge(challenge, true),
                      child: const Text('ACCEPT'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final allChallenges = challengeProvider.challenges;
    final pendingChallenges = challengeProvider.pendingChallenges;

    // Separate active and completed challenges
    final activeChallenges = allChallenges
        .where((c) => c.status == 'ACCEPTED')
        .toList();

    final completedChallenges = allChallenges
        .where((c) => c.status == 'COMPLETED' || c.status == 'DECLINED')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
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
                    onPressed: _loadChallenges,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadChallenges,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pending Tab
                  pendingChallenges.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No pending challenges'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _goToCreateChallenge,
                                child: const Text('Send a Challenge'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: pendingChallenges.length,
                          itemBuilder: (context, index) {
                            return _buildChallengeItem(
                              pendingChallenges[index],
                            );
                          },
                        ),

                  // Active Tab
                  activeChallenges.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No active challenges'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _goToCreateChallenge,
                                child: const Text('Send a Challenge'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: activeChallenges.length,
                          itemBuilder: (context, index) {
                            return _buildChallengeItem(activeChallenges[index]);
                          },
                        ),

                  // History Tab
                  completedChallenges.isEmpty
                      ? const Center(child: Text('No completed challenges'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: completedChallenges.length,
                          itemBuilder: (context, index) {
                            return _buildChallengeItem(
                              completedChallenges[index],
                            );
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreateChallenge,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
