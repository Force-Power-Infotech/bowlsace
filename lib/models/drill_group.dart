import 'drill.dart';

class DrillGroup {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final List<Drill>? drills;
  final int createdBy;
  final DateTime createdAt;

  DrillGroup({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.drills,
    required this.createdBy,
    required this.createdAt,
  });

  factory DrillGroup.fromJson(Map<String, dynamic> json) {
    return DrillGroup(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      drills: json['drills'] != null
          ? (json['drills'] as List).map((e) => Drill.fromJson(e)).toList()
          : null,
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (drills != null) 'drills': drills!.map((e) => e.toJson()).toList(),
    };
  }
}
