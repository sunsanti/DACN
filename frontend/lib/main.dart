import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Quý nhớ kiểm tra tên file này xem có đúng là patient_home_screen.dart không nhé
import 'views/patient/patient_home_screen.dart';
import 'views/patient/main_screen.dart';
import 'views/doctor/doctor_main_screen.dart'; // Đã import màn hình bác sĩ sẵn sàng

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical App',
      debugShowCheckedModeBanner: false,

      // CHỈ DÙNG 1 THEME DUY NHẤT Ở ĐÂY
      theme: ThemeData(
        useMaterial3: true,
        // Tông màu chủ đạo là Teal (Xanh mòng két) cực hợp với ngành y tế
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
        ),
        // Áp dụng font Be Vietnam Pro cho toàn bộ App
        textTheme: GoogleFonts.beVietnamProTextTheme(
          Theme.of(context).textTheme,
        ),
      ),

      // ĐÃ ĐỔI: Chuyển hướng thẳng vào trang DoctorMainScreen
      home: const DoctorMainScreen(),
    );
  }
}
