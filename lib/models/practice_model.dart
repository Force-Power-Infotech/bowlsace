import 'drill.dart';
import 'drill_group.dart';
import 'user.dart';

class PracticeSession {
  final int id;
  final int userId;
  final int drillGroupId;
  final int drillId;
  final DateTime createdAt;
  final Drill? drill;
  final DrillGroup? drillGroup;
  final User? user;

  PracticeSession({
    required this.id,
    required this.userId,
    required this.drillGroupId,
    required this.drillId,
    required this.createdAt,
    this.drill,
    this.drillGroup,
    this.user,
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      drillGroupId: json['drill_group_id'] as int,
      drillId: json['drill_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      drill: json['drill'] != null ? Drill.fromJson(json['drill']) : null,
      drillGroup: json['drill_group'] != null
          ? DrillGroup.fromJson(json['drill_group'])
          : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'drill_group_id': drillGroupId,
      'drill_id': drillId,
      'created_at': createdAt.toIso8601String(),
      if (drill != null) 'drill': drill!.toJson(),
      if (drillGroup != null) 'drill_group': drillGroup!.toJson(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  @override
  String toString() {
    return 'PracticeSession{id: $id, userId: $userId, drillGroupId: $drillGroupId, drillId: $drillId, createdAt: $createdAt}';
  }
}
