class PracticeSession {
  final String id;
  final String drillGroupId;
  final String drillId;
  final String userId;
  final int duration;
  final int shots;
  final String notes;
  final double accuracy;
  final DateTime createdAt;

  PracticeSession({
    required this.id,
    required this.drillGroupId,
    required this.drillId,
    required this.userId,
    required this.duration,
    required this.shots,
    required this.notes,
    required this.accuracy,
    required this.createdAt,
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['id'] as String,
      drillGroupId: json['drill_group_id'] as String,
      drillId: json['drill_id'] as String,
      userId: json['user_id'] as String,
      duration: json['duration'] as int,
      shots: json['shots'] as int,
      notes: json['notes'] as String? ?? '',
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'drill_group_id': drillGroupId,
      'drill_id': drillId,
      'user_id': userId,
      'duration': duration,
      'shots': shots,
      'notes': notes,
      'accuracy': accuracy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
