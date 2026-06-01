import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/patient_model.dart'; 
import '../models/appointment_model.dart'; 
import '../models/doctor_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.56.1:3000';
  static const bool isOfflineMode = false; 

  // 1. Hàm test kết nối lúc mở app
  static Future<void> testConnection() async {
    if (isOfflineMode) return;
    try {
      final response = await http.get(Uri.parse('$baseUrl/patient/1'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("🎉 THÀNH CÔNG: Flutter đã nối được với NestJS!");
      }
    } catch (e) {
      print("❌ LỖI: Không tìm thấy Backend: $e");
    }
  }

  // 2. Hàm lấy thông tin Bệnh nhân (GET)
  static Future<Patient?> getPatientProfile(int patientId) async {
    if (isOfflineMode) {
      await Future.delayed(const Duration(milliseconds: 500)); 
      return Patient.fromJson({
        'id': 1, 'name': 'Thái Văn Quý (Offline)', 'gender': 'male',
        'age': 22, 'birthDate': '2004-01-01', 'email': 'quy@gmail.com',
        'phone': '0901234567', 'address': 'TP. Hồ Chí Minh'
      });
    }
    try {
      final response = await http.get(Uri.parse('$baseUrl/patient/$patientId'));
      if (response.statusCode == 200) {
        return Patient.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Lỗi API lấy profile: $e");
      return null;
    }
  }

  // 3. Hàm gửi dữ liệu cập nhật của Bệnh nhân lên Backend (PATCH)
  static Future<bool> updatePatientProfile(int patientId, Map<String, dynamic> updateData) async {
    if (isOfflineMode) return true;
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/patient/$patientId'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(updateData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Lỗi API cập nhật profile: $e");
      return false;
    }
  }

  // =========================================================================
  // 🌟 CÁC HÀM MỚI TOÀN NĂNG DÀNH CHO LỊCH HẸN (APPOINTMENT) NẰM Ở ĐÂY:
  
  // 4. Hàm lấy danh sách lịch hẹn của bệnh nhân (GET)
  static Future<List<Appointment>> getAppointments(int patientId) async {
    if (isOfflineMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        Appointment(id: 101, apTime: DateTime.now().add(const Duration(days: 2)), address: "Phòng khám 01 - Bệnh viện ĐK", confirmCondition: 0, doctorName: "BS. Nguyễn Văn A", note: "Khám ho, sốt"),
        Appointment(id: 102, apTime: DateTime.now().subtract(const Duration(days: 3)), address: "Phòng tổng quát", confirmCondition: 1, doctorName: "BS. Trần Thị B", note: "Tái khám định kỳ"),
      ];
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/patient/$patientId/appointments'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Appointment.fromJson(item)).toList();
      } else {
        print("❌ Lỗi lấy danh sách lịch hẹn: Mã ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Lỗi kết nối API lấy lịch hẹn: $e");
      return [];
    }
  }

  // 5. Hàm gửi một lịch hẹn mới lên NestJS để lưu vào DB (POST)
  static Future<bool> createAppointment(Map<String, dynamic> appointmentData) async {
    if (isOfflineMode) {
      print("🌐 Chế độ Offline: Đã giả lập đặt lịch thành công!");
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patient/create-appointment'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(appointmentData),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Lỗi kết nối API đặt lịch: $e");
      return false;
    }
  }

  // 🌟 6. Hàm lấy danh sách khung giờ cố định 15 phút từ NestJS (GET)
  static Future<List<String>> getTimeSlots() async {
    if (isOfflineMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return ["08:00", "08:15", "08:30", "08:45", "09:00", "09:15", "09:30", "14:00", "14:15"];
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/patient/time-slots'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((slot) => slot.toString()).toList();
      } else {
        print("❌ Lỗi tải khung giờ: Mã ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Lỗi kết nối API lấy khung giờ: $e");
      return [];
    }
  }

  // 🌟 7. Hàm lọc danh sách bác sĩ rảnh thực tế theo mốc thời gian (GET)
  static Future<List<dynamic>> getAvailableDoctors(String dateTime) async {
    if (isOfflineMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      return [
        {"id": 1, "name": "BS. Nguyễn Văn A (Nội Tổng Quát)"},
        {"id": 2, "name": "BS. Trần Thị B (Sản Nhi)"},
        {"id": 3, "name": "BS. Lê Hoàng C (Tim Mạch)"}
      ];
    }

    try {
      final encodedDateTime = Uri.encodeComponent(dateTime);
      final response = await http.get(
        Uri.parse('$baseUrl/patient/available-doctors?dateTime=$encodedDateTime'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        print("❌ Lỗi lọc bác sĩ rảnh: Mã ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Lỗi kết nối API lọc bác sĩ: $e");
      return [];
    }
  }

  // 🌟 8. Hàm Đăng Ký Tài Khoản
  static Future<Map<String, dynamic>> registerPatient(String name, String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patient/register'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Lỗi máy chủ!'};
    } catch (e) {
      print("Lỗi API Đăng ký: $e");
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ'};
    }
  }

  // 🌟 9. Hàm Đăng Nhập
  static Future<Map<String, dynamic>> loginPatient(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patient/login'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Lỗi máy chủ!'};
    } catch (e) {
      print("Lỗi API Đăng nhập: $e");
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ'};
    }
  }

  // 🌟 Lấy toàn bộ lịch hẹn theo ID bệnh nhân
  static Future<List<dynamic>> getPatientAppointments(int patientId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/patient/$patientId/appointments'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Lỗi API getPatientAppointments: $e");
      return [];
    }
  }

  // 🌟 HÀM LẤY DANH SÁCH BÁC SĨ TỪ NESTJS
  static Future<List<Doctor>> getAllDoctors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/doctor/list'));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Doctor.fromJson(item)).toList();
      } else {
        print("❌ Lỗi tải danh sách bác sĩ: Mã ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Lỗi kết nối API lấy danh sách bác sĩ: $e");
      return [];
    }
  }

  // 🌟 HÀM LẤY DANH SÁCH CA LÀM VIỆC CỦA BÁC SĨ
  static Future<List<dynamic>> getDoctorShifts(int doctorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/doctor/list-shift/$doctorId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("❌ Lỗi lấy ca làm việc: $e");
      return [];
    }
  }

  // =========================================================================
  // 🌟 CÁC HÀM ĐÃ ĐƯỢC CHỈNH SỬA ĐỂ TRUYỀN THÊM DOCTOR_ID XUỐNG NESTJS:

  // 🌟 HÀM 1: LẤY DANH SÁCH LỊCH HẸN CHƯA XÁC NHẬN CỦA TỪNG BÁC SĨ
  static Future<List<dynamic>> getUnacceptedAppointments(int doctorId) async {
    try {
      // Đã cập nhật đường dẫn URL nối thêm '/$doctorId'
      final response = await http.get(Uri.parse('$baseUrl/doctor/list-unAcpappointment/$doctorId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("❌ Lỗi lấy lịch hẹn chưa xác nhận của bác sĩ $doctorId: $e");
      return [];
    }
  }

  // 🌟 HÀM 2: LẤY DANH SÁCH LỊCH HẸN ĐÃ XÁC NHẬN CỦA TỪNG BÁC SĨ
  static Future<List<dynamic>> getAcceptedAppointments(int doctorId) async {
    try {
      // Đã cập nhật đường dẫn URL nối thêm '/$doctorId'
      final response = await http.get(Uri.parse('$baseUrl/doctor/list-appointment/$doctorId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("❌ Lỗi lấy lịch hẹn đã xác nhận của bác sĩ $doctorId: $e");
      return [];
    }
  }
  // Thêm hàm này vào trong class ApiService
  static Future<bool> confirmAppointment(int appointmentId, String note) async {
    try {
      // Nhớ đảm bảo baseUrl của bạn đang trỏ đúng về localhost hoặc IP của NestJS nhé
      final response = await http.post(
        Uri.parse('$baseUrl/doctor/confirm-appointment/$appointmentId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'note': note,
          'confirmDate': DateTime.now().toIso8601String(),
        }),
      );
      // Nếu NestJS trả về 200 (OK) hoặc 201 (Created) thì là thành công
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Lỗi gọi API confirmAppointment: $e");
      return false;
    }
  }
}