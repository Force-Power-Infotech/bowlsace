class Drill {
  final int id;
  final String name;
  final String description;
  final int difficulty;
  final String? imageUrl;
  final List<String> tags;
  final int? drillGroupId;
  final DateTime createdAt;

  Drill({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    this.imageUrl,
    required this.tags,
    this.drillGroupId,
    required this.createdAt,
  });

  factory Drill.fromJson(Map<String, dynamic> json) {
    return Drill(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      difficulty: json['difficulty'],
      imageUrl: json['image_url'],
      tags: List<String>.from(json['tags'] ?? []),
      drillGroupId: json['drill_group_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'image_url': imageUrl,
      'tags': tags,
      'drill_group_id': drillGroupId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
