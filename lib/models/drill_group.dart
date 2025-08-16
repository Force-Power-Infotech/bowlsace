class DrillGroup {
  final String name;
  final String description;
  final String image;
  final int difficulty;
  final bool isPublic;
  final List<String> tags;
  final String id;
  final String? metaDrillGroupId;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DrillGroup({
    required this.name,
    required this.description,
    required this.image,
    required this.difficulty,
    required this.isPublic,
    required this.tags,
    required this.id,
    this.metaDrillGroupId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DrillGroup.fromJson(Map<String, dynamic> json) {
    return DrillGroup(
      name: json['name'] as String,
      description: json['description'] as String,
      image: json['image'] as String,
      difficulty: json['difficulty'] as int,
      isPublic: json['is_public'] as bool,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      id: json['id'] as String,
      metaDrillGroupId: json['meta_drill_group_id'] as String?,
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
