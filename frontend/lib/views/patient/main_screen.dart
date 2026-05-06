import 'package:flutter/material.dart';
import 'patient_home_screen.dart';
import 'ai_chat_screen.dart';
import 'appointment_dashboard_screen.dart';
import 'profile_screen.dart'; // Import mới

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Danh sách 4 màn hình tương ứng với 4 Tab
  final List<Widget> _screens = [
    const PatientHomeScreen(),
    const AppointmentDashboardScreen(),
    const AIChatScreen(),
    const ProfileScreen(), // Đã gắn màn hình Hồ sơ vào đây
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_rounded),
            label: "Lịch hẹn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: "AI Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Tôi",
          ),
        ],
      ),
    );
  }
}
