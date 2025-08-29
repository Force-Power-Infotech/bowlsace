class ShotRecord {
  final int shotNumber;
  final int mapLength; // 0-4 value representing the shot length
  final DateTime timestamp;

  ShotRecord({
    required this.shotNumber,
    required this.mapLength,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'shotNumber': shotNumber,
    'mapLength': mapLength,
    'timestamp': timestamp.toIso8601String(),
  };
}
