/// Maps a shift type code to a Vietnamese label.
String shiftTypeLabel(String type) {
  switch (type) {
    case 'morning':
      return 'Sáng';
    case 'afternoon':
      return 'Chiều';
    case 'evening':
      return 'Tối';
    default:
      return type;
  }
}

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

  String get typeLabel => shiftTypeLabel(type);
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
  final DateTime startTime;
  final DateTime endTime;
  final String doctorName;

  ShiftAssignment({
    required this.id,
    required this.type,
    required this.status,
    required this.duration,
    required this.startTime,
    required this.endTime,
    this.doctorName = '',
  });

  bool get isActive => status == 'ACTIVE';
  String get typeLabel => shiftTypeLabel(type);

  String get dateLabel =>
      '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}/${startTime.year}';
  String get timeLabel {
    String hm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${hm(startTime)}–${hm(endTime)}';
  }

  factory ShiftAssignment.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'];
    return ShiftAssignment(
      id: json['id'] as int,
      type: (json['type'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      duration: (json['duration'] as num?)?.toDouble() ?? 0,
      startTime: DateTime.parse(json['startTime'] as String).toLocal(),
      endTime: DateTime.parse(json['endTime'] as String).toLocal(),
      doctorName: (doctor is Map ? doctor['name'] : null) ?? '',
    );
  }
}
