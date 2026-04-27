import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // LƯU Ý QUAN TRỌNG VỀ ĐỊA CHỈ IP:
  // - Nếu chạy trên Chrome: 'http://localhost:3000/auth'
  // - Nếu chạy trên máy ảo (Android Emulator/LDPlayer): 'http://10.0.2.2:3000/auth'
  // - Nếu chạy máy thật: Dùng IP LAN của máy tính (VD: 'http://192.168.1.5:3000/auth')
  final String baseUrl = 'http://localhost:3000/auth';

  // 1. Hàm gọi API Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data':
              responseData, // Trong này sẽ có access_token và role (DOCTOR/PATIENT)
        };
      } else {
        return {
          'success': false,
          'message': 'Email hoặc mật khẩu không chính xác!',
        };
      }
    } catch (e) {
      print('=== LỖI KẾT NỐI: $e ===');
      return {
        'success': false,
        'message': 'Không thể kết nối tới Server. Vui lòng kiểm tra lại!',
      };
    }
  }

  // 2. Hàm gọi API Đăng ký (ĐÃ CẬP NHẬT NAME VÀ AGE)
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required int age,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'age': age,
          // Lưu ý: Không cần gửi role nữa vì backend đã mặc định là Patient
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Đăng ký bệnh nhân thành công!'};
      } else {
        // Trích xuất lỗi từ Backend nếu có (ví dụ: email đã tồn tại)
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Đăng ký thất bại!',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ!'};
    }
  }
}
