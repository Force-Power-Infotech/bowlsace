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
    try {
      print('Creating PracticeSession from JSON:');
      print('id: ${json['id']}');
      print('user_id: ${json['user_id']}');
      print('drill_group_id: ${json['drill_group_id']}');
      print('drill_id: ${json['drill_id']}');
      print('created_at: ${json['created_at']}');
      print('drill: ${json['drill']}');
      print('drill_group: ${json['drill_group']}');
      print('user: ${json['user']}');

      return PracticeSession(
        id: json['id'] as int? ?? 0,
        userId: json['user_id'] as int? ?? 0,
        drillGroupId: json['drill_group_id'] as int? ?? 0,
        drillId: json['drill_id'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        drill: json['drill'] != null
            ? Drill.fromJson(json['drill'] as Map<String, dynamic>)
            : null,
        drillGroup: json['drill_group'] != null
            ? DrillGroup.fromJson(json['drill_group'] as Map<String, dynamic>)
            : null,
        user: json['user'] != null
            ? User.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );
    } catch (e, stackTrace) {
      print('Error parsing practice session: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
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
