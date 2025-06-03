class DashboardMetrics {
  final int totalPracticeCount;
  final int totalDrillsCompleted;
  final int totalChallengesWon;
  final int totalSessionTimeMinutes;
  final List<ActivityPoint> activityHistory;
  final List<SkillMetric> skillsByCategory;

  DashboardMetrics({
    required this.totalPracticeCount,
    required this.totalDrillsCompleted,
    required this.totalChallengesWon,
    required this.totalSessionTimeMinutes,
    required this.activityHistory,
    required this.skillsByCategory,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalPracticeCount: json['total_practice_count'],
      totalDrillsCompleted: json['total_drills_completed'],
      totalChallengesWon: json['total_challenges_won'],
      totalSessionTimeMinutes: json['total_session_time_minutes'],
      activityHistory: (json['activity_history'] as List)
          .map((e) => ActivityPoint.fromJson(e))
          .toList(),
      skillsByCategory: (json['skills_by_category'] as List)
          .map((e) => SkillMetric.fromJson(e))
          .toList(),
    );
  }
}

class ActivityPoint {
  final DateTime date;
  final int practiceCount;

  ActivityPoint({required this.date, required this.practiceCount});

  factory ActivityPoint.fromJson(Map<String, dynamic> json) {
    return ActivityPoint(
      date: DateTime.parse(json['date']),
      practiceCount: json['practice_count'],
    );
  }
}

class SkillMetric {
  final String category;
  final double score;

  SkillMetric({required this.category, required this.score});

  factory SkillMetric.fromJson(Map<String, dynamic> json) {
    return SkillMetric(
      category: json['category'],
      score: json['score'].toDouble(),
    );
  }
}
