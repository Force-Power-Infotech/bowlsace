import 'package:flutter/material.dart';
import 'drill.dart';

class DrillGroup {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final Color accentColor;
  final List<Drill> drills;
  final DateTime createdAt;
  final bool isCustom;
  final String? category; // e.g., 'Beginner', 'Advanced', etc.
  final int totalDuration; // Total minutes of all drills
  final double difficulty; // 1-5 scale
  final List<String> tags;

  DrillGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.accentColor,
    required this.drills,
    required this.createdAt,
    this.isCustom = false,
    this.category,
    required this.totalDuration,
    required this.difficulty,
    required this.tags,
  });

  factory DrillGroup.fromJson(Map<String, dynamic> json) {
    return DrillGroup(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      accentColor: Color(json['accent_color']),
      drills: (json['drills'] as List)
          .map((drill) => Drill.fromJson(drill))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      isCustom: json['is_custom'] ?? false,
      category: json['category'],
      totalDuration: json['total_duration'] ?? 0,
      difficulty: (json['difficulty'] ?? 3.0).toDouble(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'accent_color': accentColor.value,
      'drills': drills.map((drill) => drill.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'is_custom': isCustom,
      'category': category,
      'total_duration': totalDuration,
      'difficulty': difficulty,
      'tags': tags,
    };
  }
}
