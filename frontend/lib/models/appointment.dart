class Appointment {
  final int id;
  final DateTime apTime;
  final String address;
  final String? note;
  final int confirmCondition; // 1 = chờ xác nhận, 0 = đã xác nhận
  final String doctorName;

  Appointment({
    required this.id,
    required this.apTime,
    required this.address,
    required this.note,
    required this.confirmCondition,
    required this.doctorName,
  });

  bool get isConfirmed => confirmCondition == 0;
  String get statusLabel => isConfirmed ? 'Đã xác nhận' : 'Chờ xác nhận';

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'];
    return Appointment(
      id: json['id'] as int,
      apTime: DateTime.parse(json['apTime'] as String).toLocal(),
      address: (json['address'] ?? '') as String,
      note: json['note'] as String?,
      confirmCondition: (json['confirmCondition'] ?? 1) as int,
      doctorName: (json['doctorName'] ??
          (doctor is Map ? doctor['name'] : null) ??
          '') as String,
    );
  }
}
