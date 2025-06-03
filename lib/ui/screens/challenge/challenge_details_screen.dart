import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di/service_locator.dart';
import '../../../models/challenge.dart';
import '../../../providers/challenge_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../repositories/challenge_repository.dart';
import '../../../api/api_error_handler.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailsScreen({Key? key, required this.challenge})
    : super(key: key);

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  final ChallengeRepository _challengeRepository = getIt<ChallengeRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  // Score tracking for challenge completion
  int _userScore = 0;
  int _opponentScore = 0;
  bool _isSubmittingResult = false;

  @override
  void initState() {
    super.initState();
    _loadChallengeDetails();
  }

  Future<void> _loadChallengeDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch the latest challenge details from the repository
      final challengeDetails = await _challengeRepository.getChallenge(
        widget.challenge.id,
      );

      if (!mounted) return;

      // Update the challenge in the provider
      Provider.of<ChallengeProvider>(
        context,
        listen: false,
      ).updateChallenge(challengeDetails);
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load challenge details';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _respondToChallenge(bool accept) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Challenge updatedChallenge;
      if (accept) {
        updatedChallenge = await _challengeRepository.acceptChallenge(
          widget.challenge.id,
        );
      } else {
        updatedChallenge = await _challengeRepository.declineChallenge(
          widget.challenge.id,
        );
      }

      if (!mounted) return;

      // Update the challenge in the provider
      Provider.of<ChallengeProvider>(
        context,
        listen: false,
      ).updateChallenge(updatedChallenge);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Challenge ${accept ? 'accepted' : 'declined'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to respond to challenge';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitChallengeResult() async {
    // Validate scores
    if (_userScore == _opponentScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A challenge must have a winner and loser'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingResult = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.user?.id ?? 0;

      // Determine the winner ID based on the scores
      final isUserWinner = _userScore > _opponentScore;
      final winnerId = isUserWinner
          ? currentUserId
          : (currentUserId == widget.challenge.senderId
                ? widget.challenge.recipientId
                : widget.challenge.senderId);

      // Prepare results data
      final results = {
        'winner_user_id': winnerId,
        'user_score': _userScore,
        'opponent_score': _opponentScore,
      };

      // Submit to repository
      final updatedChallenge = await _challengeRepository.completeChallenge(
        widget.challenge.id,
        results,
      );

      if (!mounted) return;

      // Update the challenge in the provider
      Provider.of<ChallengeProvider>(
        context,
        listen: false,
      ).updateChallenge(updatedChallenge);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Challenge marked as completed. ${isUserWinner ? 'You won!' : 'Your opponent won.'}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to submit results')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingResult = false;
        });
      }
    }
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Challenge Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the final scores:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Your Score'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _userScore > 0
                                  ? () {
                                      setState(() {
                                        _userScore--;
                                      });
                                    }
                                  : null,
                            ),
                            Text(
                              '$_userScore',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  _userScore++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Opponent Score'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _opponentScore > 0
                                  ? () {
                                      setState(() {
                                        _opponentScore--;
                                      });
                                    }
                                  : null,
                            ),
                            Text(
                              '$_opponentScore',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  _opponentScore++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('CANCEL'),
          ),
          _isSubmittingResult
              ? const CircularProgressIndicator()
              : TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _submitChallengeResult();
                  },
                  child: const Text('SUBMIT'),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the latest challenge data from the provider
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final challenge = challengeProvider.selectedChallenge ?? widget.challenge;

    // Get current user ID
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.user?.id ?? 0;

    // Determine if the current user is the sender or recipient
    final isSender = challenge.senderId == currentUserId;
    final otherPersonName = isSender
        ? challenge.recipientName
        : challenge.senderName;

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge Details')),
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
                    onPressed: _loadChallengeDetails,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenge Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _buildStatusChip(challenge.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Challenge participants
                          const Text(
                            'Participants',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.person_outline),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Challenger: ${challenge.senderName}',
                                      style: TextStyle(
                                        fontWeight:
                                            challenge.senderId == currentUserId
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Opponent: ${challenge.recipientName}',
                                      style: TextStyle(
                                        fontWeight:
                                            challenge.recipientId ==
                                                currentUserId
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Challenge Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Challenge Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (challenge.drillName != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.sports),
                                const SizedBox(width: 8),
                                Text('Drill: ${challenge.drillName}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (challenge.completionDeadline != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 8),
                                Text(
                                  'Deadline: ${_formatDate(challenge.completionDeadline!)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 8),
                              Text(
                                'Created: ${_formatDate(challenge.createdAt)}',
                              ),
                            ],
                          ),
                          if (challenge.updatedAt != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.update),
                                const SizedBox(width: 8),
                                Text(
                                  'Last Updated: ${_formatDate(challenge.updatedAt!)}',
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Result section (visible only for completed challenges)
                  if (challenge.status == 'COMPLETED') ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Result',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.emoji_events),
                                const SizedBox(width: 8),
                                Text(
                                  'Winner: ${challenge.winnerUserId == currentUserId ? "You" : otherPersonName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // Here you would display the scores if they are available in your model
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  if (challenge.status == 'PENDING' && !isSender) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _respondToChallenge(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('DECLINE'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _respondToChallenge(true),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('ACCEPT'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Complete Challenge button (only for accepted challenges)
                  if (challenge.status == 'ACCEPTED') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _showCompleteDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('RECORD RESULT'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String displayText;

    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        displayText = 'Pending';
        break;
      case 'ACCEPTED':
        color = Colors.blue;
        displayText = 'In Progress';
        break;
      case 'COMPLETED':
        color = Colors.green;
        displayText = 'Completed';
        break;
      case 'DECLINED':
        color = Colors.grey;
        displayText = 'Declined';
        break;
      default:
        color = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(displayText, style: TextStyle(color: color)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
