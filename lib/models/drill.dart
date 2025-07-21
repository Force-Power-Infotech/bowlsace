import 'package:flutter/material.dart';

class Drill {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final int durationMinutes;
  final double difficulty;
  final List<String> tags;
  final DateTime createdAt;
  final int targetScore;
  final String? drillType;
  final int? sessionId;

  Drill({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.durationMinutes,
    required this.difficulty,
    this.tags = const [],
    required this.createdAt,
    required this.targetScore,
    this.drillType,
    this.sessionId,
  });

  factory Drill.fromJson(Map<String, dynamic> json) {
    // Handle fields according to the API response shown in Swagger UI
    return Drill(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      difficulty: (json['difficulty'] as num? ?? 3.0).toDouble(),
      tags: json['tags'] != null 
          ? (json['tags'] as List<dynamic>).map((e) => e.toString()).toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      targetScore: json['target_score'] as int? ?? 80,
      drillType: json['drill_type'] as String?,
      sessionId: json['session_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'duration_minutes': durationMinutes,
      'difficulty': difficulty,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'target_score': targetScore,
      'drill_type': drillType,
      'session_id': sessionId,
    };
  }
}
