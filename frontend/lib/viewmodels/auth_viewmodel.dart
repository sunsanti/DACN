import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  String _userRole = ''; // Thêm biến này để lưu role (DOCTOR/PATIENT)

  final AuthService _authService = AuthService();

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get userRole => _userRole; // Getter để UI truy cập

  // 1. Hàm Đăng nhập
  Future<bool> login(String email, String password) async {
    // Validate cơ bản
    if (email.isEmpty || !email.contains('@')) {
      _errorMessage = 'Vui lòng nhập đúng định dạng email!';
      notifyListeners();
      return false;
    }
    if (password.length < 3) {
      // Để 3 cho dễ test, sau này đổi lại 6 nhé Quý
      _errorMessage = 'Mật khẩu quá ngắn!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    final result = await _authService.login(email, password);

    _isLoading = false;

    if (result['success'] == true) {
      // QUAN TRỌNG: Lấy role từ data trả về
      _userRole = result['data']['role'] ?? 'PATIENT';
      // Lưu ý: access_token nằm ở result['data']['access_token']

      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // 2. Hàm Đăng ký (ĐÃ CẬP NHẬT THEO BACKEND MỚI)
  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
    required int age,
  }) async {
    // Validate
    if (name.isEmpty) {
      _errorMessage = 'Vui lòng nhập họ tên!';
      notifyListeners();
      return false;
    }
    if (age <= 0) {
      _errorMessage = 'Tuổi không hợp lệ!';
      notifyListeners();
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      _errorMessage = 'Email không hợp lệ!';
      notifyListeners();
      return false;
    }
    if (password != confirmPassword) {
      _errorMessage = 'Mật khẩu xác nhận không khớp!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Gọi Service với đầy đủ thông tin mới
    final result = await _authService.register(
      email: email,
      password: password,
      name: name,
      age: age,
    );

    _isLoading = false;
    if (result['success'] == true) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
