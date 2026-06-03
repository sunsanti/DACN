class ShiftTemplate {
  final int id;
  final String type;
  final DateTime startTime;
  final DateTime endTime;

  ShiftTemplate({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
  });

  double get hours => endTime.difference(startTime).inMinutes / 60.0;

  factory ShiftTemplate.fromJson(Map<String, dynamic> json) => ShiftTemplate(
        id: json['id'] as int,
        type: (json['type'] ?? '') as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
      );
}

class ShiftAssignment {
  final int id;
  final String type;
  final String status;
  final double duration;

  ShiftAssignment({
    required this.id,
    required this.type,
    required this.status,
    required this.duration,
  });

  bool get isActive => status == 'ACTIVE';

  factory ShiftAssignment.fromJson(Map<String, dynamic> json) => ShiftAssignment(
        id: json['id'] as int,
        type: (json['type'] ?? '') as String,
        status: (json['status'] ?? '') as String,
        duration: (json['duration'] as num?)?.toDouble() ?? 0,
      );
}
