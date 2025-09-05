// lib/models/practice_session_detail.dart
import 'package:flutter/foundation.dart';

@immutable
class ShotEntry {
  final int? matLength; // "mat_length" in API
  final int? shotNumber; // "shot_number"
  final DateTime? createdAt; // "created_at"

  const ShotEntry({this.matLength, this.shotNumber, this.createdAt});

  factory ShotEntry.fromJson(Map<String, dynamic> json) => ShotEntry(
    matLength: json['mat_length'] as int?,
    shotNumber: json['shot_number'] as int?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
  );
}

@immutable
class SubDrillEntryOut {
  final String id; // entry row id in session_drill_subdrills
  final String drillEntryId; // parent drill entry id
  final String subDrillId; // original catalog sub-drill id
  final String title;
  final int shots; // target or completed (as per API)
  final int durationSeconds;
  final List<ShotEntry> shotList;

  const SubDrillEntryOut({
    required this.id,
    required this.drillEntryId,
    required this.subDrillId,
    required this.title,
    required this.shots,
    required this.durationSeconds,
    required this.shotList,
  });

  factory SubDrillEntryOut.fromJson(Map<String, dynamic> json) =>
      SubDrillEntryOut(
        id: json['id'] as String,
        drillEntryId: json['drill_entry_id'] as String,
        subDrillId: json['sub_drill_id'] as String,
        title: json['title'] as String? ?? '',
        shots: (json['shots'] as num?)?.toInt() ?? 0,
        durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
        shotList: (json['shot_list'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ShotEntry.fromJson)
            .toList(),
      );
}

@immutable
class DrillEntryOut {
  final String id; // session drill entry id
  final String sessionId;
  final String drillId; // original catalog drill id
  final String name;
  final int durationSeconds;
  final int shots;
  final int accuracy;
  final String notes;
  final List<SubDrillEntryOut> subDrills;
  final List<ShotEntry> shotList;

  const DrillEntryOut({
    required this.id,
    required this.sessionId,
    required this.drillId,
    required this.name,
    required this.durationSeconds,
    required this.shots,
    required this.accuracy,
    required this.notes,
    required this.subDrills,
    required this.shotList,
  });

  factory DrillEntryOut.fromJson(Map<String, dynamic> json) => DrillEntryOut(
    id: json['id'] as String,
    sessionId: json['session_id'] as String,
    drillId: json['drill_id'] as String,
    name: json['name'] as String? ?? '',
    durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
    shots: (json['shots'] as num?)?.toInt() ?? 0,
    accuracy: (json['accuracy'] as num?)?.toInt() ?? 0,
    notes: json['notes'] as String? ?? '',
    subDrills: (json['sub_drills'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SubDrillEntryOut.fromJson)
        .toList(),
    shotList: (json['shot_list'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ShotEntry.fromJson)
        .toList(),
  );
}

@immutable
class PracticeSessionDetail {
  final String id;
  final String userId;
  final String drillGroupId;
  final String drillGroupName;
  final int totalDurationSeconds;
  final int totalShots;
  final int avgAccuracy;
  final DateTime? startedAt;
  final DateTime? createdAt;
  final List<DrillEntryOut> drills;
  final List<ShotEntry> shotList;
  final String? idempotencyKey;

  const PracticeSessionDetail({
    required this.id,
    required this.userId,
    required this.drillGroupId,
    required this.drillGroupName,
    required this.totalDurationSeconds,
    required this.totalShots,
    required this.avgAccuracy,
    required this.startedAt,
    required this.createdAt,
    required this.drills,
    required this.shotList,
    required this.idempotencyKey,
  });

  factory PracticeSessionDetail.fromJson(Map<String, dynamic> json) =>
      PracticeSessionDetail(
        id: json['id'] as String,
        userId: json['user_id']?.toString() ?? '',
        drillGroupId: json['drill_group_id'] as String,
        drillGroupName: json['drill_group_name'] as String? ?? '',
        totalDurationSeconds:
            (json['total_duration_seconds'] as num?)?.toInt() ?? 0,
        totalShots: (json['total_shots'] as num?)?.toInt() ?? 0,
        avgAccuracy: (json['avg_accuracy'] as num?)?.toInt() ?? 0,
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        drills: (json['drills'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DrillEntryOut.fromJson)
            .toList(),
        shotList: (json['shot_list'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ShotEntry.fromJson)
            .toList(),
        idempotencyKey: json['idempotency_key'] as String?,
      );

  /// Convenience: map original drill_id -> session drill entry id
  Map<String, String> buildEntryIdMap() {
    final map = <String, String>{};
    for (final d in drills) {
      map[d.drillId] = d.id;
    }
    return map;
  }
}
