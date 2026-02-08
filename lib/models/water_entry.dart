class WaterEntry {
  final int? id;
  final DateTime timestamp;
  final int milliliters;

  WaterEntry({
    this.id,
    required this.timestamp,
    required this.milliliters,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'milliliters': milliliters,
    };
  }

  factory WaterEntry.fromMap(Map<String, dynamic> map) {
    return WaterEntry(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      milliliters: map['milliliters'] as int,
    );
  }
}
