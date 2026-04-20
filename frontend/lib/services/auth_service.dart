import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // LƯU Ý QUAN TRỌNG VỀ ĐỊA CHỈ IP:
  // - Nếu Quý đang chạy app trên Chrome: dùng 'http://localhost:3000/auth'
  // - Nếu Quý đang chạy trên máy ảo LDPlayer: dùng 'http://10.0.2.2:3000/auth' (hoặc IP LAN của máy tính)
  final String baseUrl = 'http://localhost:3000/auth';

  // Hàm gọi API Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        // Chuyển dữ liệu thành chuỗi JSON trước khi gửi
        body: jsonEncode({'email': email, 'password': password}),
      );

      // Nếu Backend trả về thành công (Mã 200 hoặc 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body), // Trả về Token từ server
        };
      } else {
        // Có thể do sai pass, không tồn tại user...
        return {
          'success': false,
          'message': 'Email hoặc mật khẩu không chính xác!',
        };
      }
    } catch (e) {
      print('=== LỖI MẠNG THỰC TẾ: $e ==='); // Thêm dòng này
      return {
        'success': false,
        'message': 'Không thể kết nối tới Server. Vui lòng thử lại!',
      };
    }
  }

  // Hàm gọi API Đăng ký
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          // Mặc định role là PATIENT (Bệnh nhân) như đã định nghĩa ở backend
          'role': 'PATIENT',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Đăng ký thành công!'};
      } else {
        return {
          'success': false,
          'message': 'Email đã tồn tại hoặc có lỗi xảy ra!',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ!'};
    }
  }
}
