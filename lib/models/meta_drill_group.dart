class MetaDrillGroup {
  final String name;
  final String description;
  final String? imageUrl;
  final bool isActive;
  final String id;
  final DateTime createdAt;

  MetaDrillGroup({
    required this.name,
    required this.description,
    this.imageUrl,
    required this.isActive,
    required this.id,
    required this.createdAt,
  });

  factory MetaDrillGroup.fromJson(Map<String, dynamic> json) {
    return MetaDrillGroup(
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool,
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
