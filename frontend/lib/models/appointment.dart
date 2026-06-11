class Appointment {
  final int id;
  final DateTime apTime;
  final String address;
  final String? note; // ghi chú bệnh nhân
  final String? doctorNote; // ghi chú bác sĩ
  final int confirmCondition; // 1 = chờ, 0 = đã xác nhận, 2 = đã khám xong
  final String? cancelReason;
  final String? canceledBy; // 'patient' | 'doctor'
  final bool rescheduled;
  final String doctorName;
  final int? doctorId;
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
    required this.doctorNote,
    required this.confirmCondition,
    required this.cancelReason,
    required this.canceledBy,
    required this.rescheduled,
    required this.doctorName,
    required this.doctorId,
    required this.patientName,
    required this.patientPhone,
    required this.patientAge,
    required this.patientAddress,
    required this.patientId,
  });

  bool get isCanceled => cancelReason != null && cancelReason!.isNotEmpty;
  bool get canceledByDoctor => canceledBy == 'doctor';
  bool get isPending => !isCanceled && confirmCondition == 1;
  bool get isConfirmed => !isCanceled && confirmCondition == 0;
  bool get isExamined => !isCanceled && confirmCondition == 2;
  bool get canReschedule => !isCanceled && !rescheduled && confirmCondition != 2;

  String get statusLabel => isCanceled
      ? 'Đã hủy'
      : isExamined
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
      doctorNote: json['doctorNote'] as String?,
      confirmCondition: (json['confirmCondition'] ?? 1) as int,
      cancelReason: json['cancelReason'] as String?,
      canceledBy: json['canceledBy'] as String?,
      rescheduled: (json['rescheduled'] ?? false) as bool,
      doctorName: (json['doctorName'] ??
          (doctor is Map ? doctor['name'] : null) ??
          '') as String,
      doctorId: doctor is Map ? doctor['id'] as int? : null,
      patientName: (patient['name'] ?? '') as String,
      patientPhone: (patient['phone'] ?? '') as String,
      patientAge: (patient['age'] as num?)?.toInt() ?? 0,
      patientAddress: (patient['address'] ?? '') as String,
      patientId: patient['id'] as int?,
    );
  }
}
