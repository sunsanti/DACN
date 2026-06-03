class Appointment {
  final int id;
  final DateTime apTime;
  final String address;
  final String? note;
  final int confirmCondition; // 1 = chờ, 0 = đã xác nhận, 2 = đã khám xong
  final String doctorName;
  final String patientName;
  final String patientPhone;
  final int patientAge;
  final String patientAddress;
  final int? patientId;

  Appointment({
    required this.id,
    required this.apTime,
    required this.address,
    required this.note,
    required this.confirmCondition,
    required this.doctorName,
    required this.patientName,
    required this.patientPhone,
    required this.patientAge,
    required this.patientAddress,
    required this.patientId,
  });

  bool get isPending => confirmCondition == 1;
  bool get isConfirmed => confirmCondition == 0;
  bool get isExamined => confirmCondition == 2;
  String get statusLabel => isExamined
      ? 'Đã khám xong'
      : isConfirmed
          ? 'Đã xác nhận'
          : 'Chờ xác nhận';

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'];
    final patient = json['patient'] is Map
        ? Map<String, dynamic>.from(json['patient'])
        : <String, dynamic>{};
    return Appointment(
      id: json['id'] as int,
      apTime: DateTime.parse(json['apTime'] as String).toLocal(),
      address: (json['address'] ?? '') as String,
      note: json['note'] as String?,
      confirmCondition: (json['confirmCondition'] ?? 1) as int,
      doctorName: (json['doctorName'] ??
          (doctor is Map ? doctor['name'] : null) ??
          '') as String,
      patientName: (patient['name'] ?? '') as String,
      patientPhone: (patient['phone'] ?? '') as String,
      patientAge: (patient['age'] as num?)?.toInt() ?? 0,
      patientAddress: (patient['address'] ?? '') as String,
      patientId: patient['id'] as int?,
    );
  }
}
