import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Đừng quên import file service vừa tạo

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';

  // Khởi tạo AuthService
  final AuthService _authService = AuthService();

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    // 1. Validate (Giữ nguyên đoạn này)
    if (email.isEmpty || !email.contains('@')) {
      _errorMessage = 'Vui lòng nhập đúng định dạng email!';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự!';
      notifyListeners();
      return false;
    }

    // 2. Bắt đầu gọi API
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // 3. Gọi hàm login từ AuthService (Thay vì giả lập)
    final result = await _authService.login(email, password);

    _isLoading = false; // Tắt vòng xoay loading

    if (result['success'] == true) {
      // TODO ở bước tiếp theo: Lấy JWT Token từ result['data'] và lưu vào SharedPreferences
      notifyListeners();
      return true;
    } else {
      // Gán thông báo lỗi từ server trả về để hiển thị lên màn hình
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Hàm xử lý Đăng ký
  Future<bool> register(
    String email,
    String password,
    String confirmPassword,
  ) async {
    // 1. Validate
    if (email.isEmpty || !email.contains('@')) {
      _errorMessage = 'Email không hợp lệ!';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Mật khẩu phải từ 6 ký tự trở lên!';
      notifyListeners();
      return false;
    }
    if (password != confirmPassword) {
      _errorMessage = 'Mật khẩu xác nhận không khớp!';
      notifyListeners();
      return false;
    }

    // 2. Bật loading và gọi API
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    final result = await _authService.register(email, password);

    _isLoading = false;
    if (result['success'] == true) {
      notifyListeners();
      return true; // Thành công
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false; // Thất bại
    }
  }
}
