import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Lấy ViewModel ra để sử dụng
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo hoặc Icon Y tế
              Icon(Icons.local_hospital, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              Text(
                'Đăng Nhập',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 30),

              // Ô nhập Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType
                    .emailAddress, // Giúp hiển thị bàn phím có dấu @
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Ô nhập Mật khẩu
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Hiển thị lỗi nếu có
              if (authViewModel.errorMessage.isNotEmpty)
                Text(
                  authViewModel.errorMessage,
                  style: TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 20),

              // Nút Đăng nhập
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: authViewModel.isLoading
                      ? null
                      : () async {
                          bool success = await authViewModel.login(
                            _emailController.text,
                            _passwordController.text,
                          );

                          if (success) {
                            // CẬP NHẬT LOGIC PHÂN QUYỀN (ROLE) TẠI ĐÂY
                            String role = authViewModel.userRole;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đăng nhập thành công với quyền: $role',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Phân luồng giao thông
                            if (role == 'DOCTOR') {
                              print(
                                ">>> Chuyển hướng sang Màn hình BÁC SĨ <<<",
                              );
                              // TODO: Sau này Quý tạo file doctor_home_screen.dart thì mở comment dòng dưới ra nhé
                              // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DoctorHomeScreen()));
                            } else {
                              print(
                                ">>> Chuyển hướng sang Màn hình BỆNH NHÂN <<<",
                              );
                              // TODO: Sau này Quý tạo file patient_home_screen.dart thì mở comment dòng dưới ra nhé
                              // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PatientHomeScreen()));
                            }
                          }
                        },
                  child: authViewModel.isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'ĐĂNG NHẬP',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  // Chuyển sang màn hình Register
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text(
                  'Chưa có tài khoản? Đăng ký bệnh nhân ngay',
                  style: TextStyle(color: Colors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
