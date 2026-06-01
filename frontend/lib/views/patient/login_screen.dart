import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart'; // Lùi 2 cấp để vào services
import 'register_screen.dart'; // Gọi trực tiếp vì nằm cùng thư mục
import 'main_screen.dart'; // Gọi trực tiếp vì nằm cùng thư mục

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState(); // Đã sửa lỗi private type
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập SĐT và mật khẩu!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Gọi API Đăng nhập từ ApiService
    final result = await ApiService.loginPatient(phone, password);
    
    setState(() => _isLoading = false);

    // Kiểm tra kết quả phản hồi từ NestJS (Đã xóa check null thừa thãi)
    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      var patientData = result['data'];
      
      // Ép kiểu ID an toàn để tránh lỗi bất đồng bộ kiểu dữ liệu (String vs Int)
      int parsedId = int.tryParse(patientData['id'].toString()) ?? 0;

      // Lưu thông tin đăng nhập vào bộ nhớ máy
      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('patientId', parsedId);
      await prefs.setString('patientName', patientData['name']?.toString() ?? "Bệnh nhân");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công!'), backgroundColor: Colors.green),
        );
        
        // Chuyển sang màn hình MainScreen và xóa hết các màn hình trước đó
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        String errorMsg = result['message'] ?? 'Sai số điện thoại hoặc mật khẩu!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.local_hospital, size: 90, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'PHÒNG KHÁM THÔNG MINH', 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 0.5),
              ),
              const Text('Dành cho Bệnh nhân', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              _isLoading 
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
              const SizedBox(height: 15),
              
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text('Chưa có tài khoản? Đăng ký ngay', style: TextStyle(fontSize: 15, color: Colors.blue)),
              ),
              
              const Divider(height: 40, thickness: 1),
              
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng Bác sĩ đăng nhập sẽ cập nhật sau!'), backgroundColor: Colors.blueGrey),
                  );
                },
                icon: const Icon(Icons.medical_services, color: Colors.teal),
                label: const Text(
                  'Bạn là Bác sĩ? Đăng nhập tại đây', 
                  style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}