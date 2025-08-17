import 'sub_drill.dart';

class Drill {
  final String name;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final int difficulty;
  final bool isActive;
  final String drillType;
  final int durationMinutes;
  final String id;
  final String drillGroupId;
  final int? creatorId;
  final List<SubDrill> subDrills;
  final int? numberOfShots;

  Drill({
    required this.name,
    required this.description,
    this.imageUrl,
    this.videoUrl,
    required this.difficulty,
    required this.isActive,
    required this.drillType,
    required this.durationMinutes,
    required this.id,
    required this.drillGroupId,
    this.creatorId,
    required this.subDrills,
    this.numberOfShots,
  });

  factory Drill.fromJson(Map<String, dynamic> json) {
    return Drill(
      name: json['name'] as String? ?? 'Untitled Drill',
      description: json['description'] as String? ?? 'No description available',
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      difficulty: json['difficulty'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      drillType: json['drill_type'] as String? ?? 'General',
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      id: json['id'] as String,
      drillGroupId: json['drill_group_id'] as String,
      creatorId: json['creator_id'] as int?,
      numberOfShots: json['number_of_shots'] as int?,
      subDrills: ((json['sub_drills'] as List?) ?? [])
          .map((drill) => SubDrill.fromJson(drill as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DrillGroupDetail {
  final String name;
  final String description;
  final String? image;
  final int difficulty;
  final bool isPublic;
  final List<String> tags;
  final String id;
  final String metaDrillGroupId;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Drill> drills;
  final int durationMinutes;

  DrillGroupDetail({
    required this.name,
    required this.description,
    this.image,
    required this.difficulty,
    required this.isPublic,
    required this.tags,
    required this.id,
    required this.metaDrillGroupId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.drills,
    required this.durationMinutes,
  });

  factory DrillGroupDetail.fromJson(Map<String, dynamic> json) {
    return DrillGroupDetail(
      name: json['name'] as String? ?? 'Untitled Group',
      description: json['description'] as String? ?? 'No description available',
      image: json['image'] as String?,
      difficulty: json['difficulty'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? true,
      tags: ((json['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
      id: json['id'] as String,
      metaDrillGroupId: json['meta_drill_group_id'] as String,
      userId: json['user_id'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      drills: ((json['drills'] as List?) ?? [])
          .map((drill) => Drill.fromJson(drill as Map<String, dynamic>))
          .toList(),
      durationMinutes: json['duration_minutes'] as int? ?? 0,
    );
  }
}
