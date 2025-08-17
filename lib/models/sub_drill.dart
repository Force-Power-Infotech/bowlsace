class SubDrill {
  final String title;
  final String instruction;
  final String drillId;
  final int? numberOfShots;
  final int? duration;
  final String id;
  final DateTime createdAt;

  SubDrill({
    required this.title,
    required this.instruction,
    required this.drillId,
    this.numberOfShots,
    this.duration,
    required this.id,
    required this.createdAt,
  });

  factory SubDrill.fromJson(Map<String, dynamic> json) {
    return SubDrill(
      title: json['title'] as String? ?? 'Untitled Sub-drill',
      instruction:
          json['instruction'] as String? ?? 'No instructions available',
      drillId: json['drill_id'] as String,
      numberOfShots: json['number_of_shots'] as int?,
      duration: json['duration'] as int?,
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
