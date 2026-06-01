import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // 🌟 Tạm ẩn: Bộ nhớ đệm để check đăng nhập

import 'services/api_service.dart';

// --- TẠM ẨN CÁC MÀN HÌNH BỆNH NHÂN ---
// import 'views/patient/main_screen.dart';
// import 'views/patient/login_screen.dart'; 
// import 'views/patient/patient_home_screen.dart';

// 🌟 MỞ IMPORT MÀN HÌNH BÁC SĨ
import 'views/doctor/doctor_main_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test kết nối API
  await ApiService.testConnection(); 

  // 🌟 Tạm ẩn logic check login bệnh nhân để vô thẳng app Bác sĩ
  // final prefs = await SharedPreferences.getInstance();
  // final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(const MyApp()); // Đã gỡ biến isLoggedIn ra
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical App - Doctor Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
        ),
        textTheme: GoogleFonts.beVietnamProTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      // 🌟 ÉP LUÔN VÀO MÀN HÌNH BÁC SĨ KHI MỞ APP
      home: const DoctorMainScreen(),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Bộ nhớ đệm để check đăng nhập

// import 'services/api_service.dart';

// // --- CÁC MÀN HÌNH BỆNH NHÂN ---
// import 'views/patient/main_screen.dart';
// import 'views/patient/login_screen.dart'; 
// import 'views/patient/patient_home_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Test kết nối API lúc khởi động
//   await ApiService.testConnection(); 

//   final prefs = await SharedPreferences.getInstance();
  
//   // 🌟 DÒNG LỆNH THẦN THÁNH: Ép xóa sạch mọi trạng thái đăng nhập cũ (isLoggedIn = true) đang kẹt trong máy
//   // Lưu ý: Sau khi thấy app đã quay về màn Login thành công, bạn hãy thêm dấu // vào đầu dòng này để ẩn nó đi nhé!
//   await prefs.clear(); 

//   // Đọc lại trạng thái (lúc này chắc chắn sẽ ra false vì đã xóa ở trên)
//   final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

//   runApp(MyApp(isLoggedIn: isLoggedIn)); 
// }

// class MyApp extends StatelessWidget {
//   final bool isLoggedIn; // Nhận trạng thái đăng nhập từ hàm main

//   const MyApp({super.key, required this.isLoggedIn});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Medical App - Patient Portal',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.teal,
//           primary: Colors.teal,
//         ),
//         textTheme: GoogleFonts.beVietnamProTextTheme(
//           Theme.of(context).textTheme,
//         ),
//       ),
//       // Tự động điều hướng: isLoggedIn = true thì vào Main, false thì vào Login
//       home: isLoggedIn ? const MainScreen() : const LoginScreen(),
//     );
//   }
// }