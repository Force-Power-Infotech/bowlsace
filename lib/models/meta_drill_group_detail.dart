class MetaDrillGroupDetail {
  final String name;
  final String description;
  final String? imageUrl;
  final bool isActive;
  final String id;
  final DateTime createdAt;
  final List<DrillGroup> drillGroups;

  MetaDrillGroupDetail({
    required this.name,
    required this.description,
    this.imageUrl,
    required this.isActive,
    required this.id,
    required this.createdAt,
    required this.drillGroups,
  });

  factory MetaDrillGroupDetail.fromJson(Map<String, dynamic> json) {
    return MetaDrillGroupDetail(
      name: json['name'] as String? ?? 'Untitled Group',
      description: json['description'] as String? ?? 'No description available',
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      drillGroups: ((json['drill_groups'] as List?) ?? [])
          .map((group) => DrillGroup.fromJson(group as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DrillGroup {
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

  DrillGroup({
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
  });

  factory DrillGroup.fromJson(Map<String, dynamic> json) {
    return DrillGroup(
      name: json['name'] as String? ?? 'Untitled Drill',
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
    );
  }
}
