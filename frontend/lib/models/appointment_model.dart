class Appointment {
  final int id;
  final DateTime apTime;
  final DateTime? confirmDate;
  final String address;
  final String? note;
  final int confirmCondition; // 0: Chờ duyệt, 1: Đã xác nhận, 2: Đã hủy
  final String doctorName;
  final String? aiDiagnosticPdf; // 🌟 1. ĐÃ THÊM: Trường lưu file PDF AI chẩn đoán

  Appointment({
    required this.id,
    required this.apTime,
    this.confirmDate,
    required this.address,
    this.note,
    required this.confirmCondition,
    required this.doctorName,
    this.aiDiagnosticPdf, // 🌟 2. ĐÃ THÊM: Constructor nhận biến này
  });

  // Hàm chuyển đổi từ JSON từ Backend trả về thành Object trong Flutter
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? 0,
      
      // 🌟 3. ĐÃ SỬA: Chuyển sang tryParse để phòng thủ từ xa, nếu Backend lỗi ngày tháng thì lấy tạm giờ hiện tại, KO BỊ SẬP APP nữa!
      apTime: DateTime.tryParse(json['apTime']?.toString() ?? '') ?? DateTime.now(),
      
      confirmDate: json['confirmDate'] != null ? DateTime.tryParse(json['confirmDate'].toString()) : null,
      address: json['address'] ?? '',
      note: json['note'],
      confirmCondition: json['confirmCondition'] ?? 0,
      doctorName: json['doctorName'] ?? 'Bác sĩ hệ thống',
      
      // 🌟 4. ĐÃ THÊM: Map dữ liệu file AI từ JSON của Backend trả về
      aiDiagnosticPdf: json['aiDiagnosticPdf'] as String?, 
    );
  }
}