import 'package:flutter/material.dart';
import 'drill.dart';

class DrillGroup {
  final int id;
  final String name;
  final String description;
  final String? image;
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
    this.image,
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
    int? userId,
  }) {
    return DrillGroup(
      id: 0, // New groups have no ID until created
      name: name,
      description: description ?? '',
      userId: userId ?? 0, // Use provided userId or default to 0
      isPublic: isPublic,
      difficulty: difficulty,
      tags: tags ?? [],
      drillIds: drillIds ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      drills: const [], // New groups start with no drills
    );
  }

  factory DrillGroup.fromJson(Map<String, dynamic> json) {
    return DrillGroup(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      image: json['image'] as String?,
      userId: json['user_id'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? true,
      difficulty: json['difficulty'] != null
          ? int.tryParse(json['difficulty'].toString()) ?? 1
          : 1,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null && json['updated_at'] != "null"
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      drills:
          (json['drills'] as List<dynamic>?)
              ?.map((drill) => Drill.fromJson(drill as Map<String, dynamic>))
              .toList() ??
          [],
      drillIds:
          (json['drill_ids'] as List<dynamic>?)
              ?.map((id) => id as int)
              .toList() ??
          [],
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
