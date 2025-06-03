import 'shot.dart';

class Session {
  final int id;
  final String name;
  final String? location;
  final String? notes;
  final int durationMinutes;
  final int userId;
  final DateTime createdAt;
  final List<Shot>? shots;
  final bool isCompleted;

  Session({
    required this.id,
    required this.name,
    this.location,
    this.notes,
    required this.durationMinutes,
    required this.userId,
    required this.createdAt,
    this.shots,
    this.isCompleted = false,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      notes: json['notes'],
      durationMinutes: json['duration_minutes'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      shots: json['shots'] != null
          ? (json['shots'] as List).map((e) => Shot.fromJson(e)).toList()
          : null,
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'notes': notes,
      'duration_minutes': durationMinutes,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'is_completed': isCompleted,
      if (shots != null) 'shots': shots!.map((e) => e.toJson()).toList(),
    };
  }
}

class SessionCreate {
  final String name;
  final String? location;
  final String? notes;
  final int durationMinutes;

  SessionCreate({
    required this.name,
    this.location,
    this.notes,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'notes': notes,
      'duration_minutes': durationMinutes,
    };
  }
}

class SessionUpdate {
  final String? name;
  final String? location;
  final String? notes;
  final int? durationMinutes;
  final bool? isCompleted;

  SessionUpdate({
    this.name,
    this.location,
    this.notes,
    this.durationMinutes,
    this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (location != null) map['location'] = location;
    if (notes != null) map['notes'] = notes;
    if (durationMinutes != null) map['duration_minutes'] = durationMinutes;
    if (isCompleted != null) map['is_completed'] = isCompleted;
    return map;
  }
}
