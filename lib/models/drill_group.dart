import 'package:flutter/material.dart';
import 'drill.dart';

class DrillGroup {
  final int id;
  final String name;
  final String description;
  final int userId;
  final bool isPublic;
  final int difficulty;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Drill> drills;
  final List<int> drillIds;

  DrillGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.isPublic,
    required this.difficulty,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.drills = const [],
    this.drillIds = const [],
  });

  // Named constructor for creating new drill groups
  factory DrillGroup.create({
    required String name,
    String? description,
    List<int>? drillIds,
    bool isPublic = true,
    List<String>? tags,
    int difficulty = 1,
  }) {
    return DrillGroup(
      id: 0,
      name: name,
      description: description ?? '',
      userId: 0,
      isPublic: isPublic,
      difficulty: difficulty,
      tags: tags ?? [],
      drillIds: drillIds ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      drills: const [],
    );
  }

  factory DrillGroup.fromJson(Map<String, dynamic> json) {
    return DrillGroup(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      userId: json['user_id'] as int? ?? 0, // Fixed: using snake_case keys from API
      isPublic: json['is_public'] as bool? ?? false, // Fixed: using snake_case keys from API
      difficulty: json['difficulty'] as int? ?? 1,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null // Fixed: using snake_case keys from API
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null // Fixed: using snake_case keys from API
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      drills: (json['drills'] as List<dynamic>?)?.map((drill) =>
              Drill.fromJson(drill as Map<String, dynamic>)).toList() ?? [],
      drillIds: (json['drill_ids'] as List<dynamic>?)?.map((id) => id as int).toList() ?? [],
    );
  }

  /// Used for API requests, only includes fields needed for creation/update
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'drill_ids': drillIds,
      'is_public': isPublic,
      'tags': tags,
      'difficulty': difficulty,
    };
  }
}
