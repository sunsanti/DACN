import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

import '../../services/api_service.dart';
import '../../models/patient_model.dart';

import 'widgets/home_header.dart';
import 'widgets/banner_slider.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/featured_doctors.dart';
import 'widgets/floating_ai_bubble.dart'; 
import 'login_screen.dart'; 

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  Patient? _patientProfile; 
  bool _isLoading = true; 
  String _savedName = "Bệnh nhân"; // Đổi tên mặc định cho chuyên nghiệp hơn

  @override
  void initState() {
    super.initState();
    _loadPatientData(); 
  }

  // 🌟 Hàm vuốt để tải lại trang (Bắt buộc phải trả về Future cho RefreshIndicator)
  Future<void> _loadPatientData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int savedId = prefs.getInt('patientId') ?? 1; 
      String? savedName = prefs.getString('patientName');

      if (savedName != null && mounted) {
        setState(() {
          _savedName = savedName;
        });
      }

      final data = await ApiService.getPatientProfile(savedId);

      if (mounted) {
        setState(() {
          _patientProfile = data;
          _isLoading = false; 
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải profile trang chủ: $e");
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  // 🌟 HÀM ĐĂNG XUẤT: Xóa sạch bộ nhớ và đẩy về Login
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Quét sạch mọi ID, trạng thái đã lưu

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Xóa hết lịch sử các trang trước
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentName = _savedName; 
    String currentAvatar = "https://api.dicebear.com/7.x/avataaars/svg?seed=$currentName";

    if (_patientProfile != null) {
      currentName = _patientProfile!.name;
      if (_patientProfile!.avatar.isNotEmpty) {
        currentAvatar = _patientProfile!.avatar;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF), 
      body: Stack(
        children: [
          // 🌟 RefreshIndicator: Bọc ngoài SingleChildScrollView để vuốt xuống load lại
          RefreshIndicator(
            onRefresh: _loadPatientData,
            color: Colors.blue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Bắt buộc để vuốt được cả khi trang ngắn
              child: Column(
                children: [
                  // TODO: Truyền thêm hàm _handleLogout vào HomeHeader nếu Header của bạn có nút Đăng xuất
                  HomeHeader(patientName: currentName, avatarUrl: currentAvatar),
                  const SizedBox(height: 10),

                  AnimationLimiter(
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 600),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          const BannerSlider(),
                          const SizedBox(height: 20),
                          const QuickActionsGrid(),
                          const SizedBox(height: 10),
                          const FeaturedDoctors(),
                          const SizedBox(height: 30), 
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const FloatingAIBubble(),
        ],
      ),
    );
  }
}