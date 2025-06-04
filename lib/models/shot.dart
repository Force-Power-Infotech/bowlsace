enum ShotResult { success, partial, miss }

class Shot {
  final int id;
  final int sessionId;
  final String drillType;
  final ShotResult result;
  final String? notes;
  final DateTime timestamp;

  Shot({
    required this.id,
    required this.sessionId,
    required this.drillType,
    required this.result,
    this.notes,
    required this.timestamp,
  });

  factory Shot.fromJson(Map<String, dynamic> json) {
    return Shot(
      id: json['id'],
      sessionId: json['session_id'],
      drillType: json['drill_type'],
      result: ShotResult.values.firstWhere(
        (e) => e.toString() == 'ShotResult.${json['result']}',
      ),
      notes: json['notes'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'drill_type': drillType,
      'result': result.toString().split('.').last,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
