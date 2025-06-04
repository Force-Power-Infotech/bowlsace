import 'package:flutter/material.dart';

class Drill {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int durationMinutes;
  final double difficulty;
  final List<String> tags;
  final DateTime createdAt;

  Drill({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.durationMinutes,
    required this.difficulty,
    required this.tags,
    required this.createdAt,
  });

  factory Drill.fromJson(Map<String, dynamic> json) {
    return Drill(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      durationMinutes: json['duration_minutes'] ?? 30,
      difficulty: (json['difficulty'] ?? 3.0).toDouble(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at']),
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
    };
  }
}
