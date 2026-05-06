class Appointment {
  final int id;
  final DateTime apTime;
  final DateTime? confirmDate;
  final String address;
  final String? note;
  final int confirmCondition; // 0: Chờ, 1: Xác nhận, 2: Hủy
  final String doctorName;
  final int patientId;
  final int doctorId;

  Appointment({
    required this.id,
    required this.apTime,
    this.confirmDate,
    required this.address,
    this.note,
    this.confirmCondition = 0,
    required this.doctorName,
    required this.patientId,
    required this.doctorId,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      apTime: DateTime.parse(json['apTime']),
      confirmDate: json['confirmDate'] != null
          ? DateTime.parse(json['confirmDate'])
          : null,
      address: json['address'],
      note: json['note'],
      confirmCondition: json['confirmCondition'] ?? 0,
      doctorName: json['doctor'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
    );
  }
}
