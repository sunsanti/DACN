import 'package:flutter/material.dart';

import 'doctor_home_screen.dart';
import 'doctor_schedule_screen.dart';
import 'doctor_patient_list_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _selectedIndex = 0;

  // --- BỘ MÀU THEME ĐỒNG BỘ ---
  final Color primaryDark = const Color(0xFF03103F);
  final Color accentBlue = const Color(0xFF0084FF);
  final Color unselectedGrey = const Color(
    0xFF94A3B8,
  ); // Xám tinh tế hơn xám mặc định

  // Biến giả lập: Số ca chưa xét duyệt (Sau này bạn kết nối API hoặc State Management truyền vào đây nhé)
  final int _unapprovedAppointments = 3;

  // Danh sách các màn hình của Bác sĩ
  final List<Widget> _screens = [
    const DoctorHomeScreen(),
    const DoctorScheduleScreen(),
    const DoctorPatientListScreen(),
    const DoctorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        // Thêm đổ bóng (shadow) nhẹ phía trên thanh điều hướng để giao diện có chiều sâu, cao cấp hơn
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor:
              accentBlue, // Đổi sang màu xanh accent đồng bộ với các trang trước
          unselectedItemColor: unselectedGrey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: "Tổng quan",
            ),
            BottomNavigationBarItem(
              // TÍNH NĂNG MỚI: Bọc Icon bằng Widget Badge để làm bong bóng thông báo
              icon: _unapprovedAppointments > 0
                  ? Badge(
                      label: Text(
                        '$_unapprovedAppointments',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      backgroundColor: const Color(
                        0xFFE11D48,
                      ), // Màu đỏ hồng ngoại giống nút chú ý bên trang chủ
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: const Icon(Icons.calendar_month_rounded),
                    )
                  : const Icon(
                      Icons.calendar_month_rounded,
                    ), // Nếu không có ca nào thì hiện icon thường
              label: "Lịch hẹn",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: "Bệnh nhân",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_rounded),
              label: "Tôi",
            ),
          ],
        ),
      ),
    );
  }
}
