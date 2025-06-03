class Challenge {
  final int id;
  final int senderId;
  final String senderName;
  final int recipientId;
  final String recipientName;
  final String status; // 'PENDING', 'ACCEPTED', 'COMPLETED', 'DECLINED'
  final int? drillId;
  final String? drillName;
  final DateTime? completionDeadline;
  final int? winnerUserId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Challenge({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.status,
    this.drillId,
    this.drillName,
    this.completionDeadline,
    this.winnerUserId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      recipientId: json['recipient_id'],
      recipientName: json['recipient_name'],
      status: json['status'],
      drillId: json['drill_id'],
      drillName: json['drill_name'],
      completionDeadline: json['completion_deadline'] != null
          ? DateTime.parse(json['completion_deadline'])
          : null,
      winnerUserId: json['winner_user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'status': status,
      'drill_id': drillId,
      'drill_name': drillName,
      'completion_deadline': completionDeadline?.toIso8601String(),
      'winner_user_id': winnerUserId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class ChallengeCreate {
  final int recipientId;
  final int? drillId;
  final DateTime? completionDeadline;

  ChallengeCreate({
    required this.recipientId,
    this.drillId,
    this.completionDeadline,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipient_id': recipientId,
      'drill_id': drillId,
      'completion_deadline': completionDeadline?.toIso8601String(),
    };
  }
}
