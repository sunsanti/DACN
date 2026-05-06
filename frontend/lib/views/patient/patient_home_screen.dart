import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Import các màn hình khác (Nếu chưa dùng tới Quý có thể comment lại)
// import 'ai_chat_screen.dart';
// import 'doctor_detail_screen.dart';

// --- IMPORT CÁC COMPONENT GIAO DIỆN CHÚNG TA ĐÃ TÁCH RIÊNG ---
import 'widgets/home_header.dart';
import 'widgets/banner_slider.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/featured_doctors.dart';
import 'widgets/floating_ai_bubble.dart'; // BONG BÓNG AI

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FBFB,
      ), // Màu nền tổng thể hơi xám xanh nhạt cho sạch
      // DÙNG STACK ĐỂ ĐÈ BONG BÓNG LÊN TRÊN CÙNG
      body: Stack(
        children: [
          // LỚP DƯỚI: Toàn bộ nội dung trang web/app có thể cuộn được
          SingleChildScrollView(
            child: Column(
              children: [
                // 1. GẮN COMPONENT HEADER
                const HomeHeader(
                  patientName: "Thái Văn Quý",
                  avatarUrl:
                      "https://api.dicebear.com/7.x/avataaars/svg?seed=Quý",
                ),
                const SizedBox(height: 10),

                // HIỆU ỨNG ANIMATION (Các thành phần sẽ trượt từ dưới lên khi mở app)
                AnimationLimiter(
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        // 2. BANNER SLIDER
                        const BannerSlider(),
                        const SizedBox(height: 20),

                        // 3. MENU CHỨC NĂNG (Giao diện thẻ Responsive mới làm)
                        const QuickActionsGrid(),
                        const SizedBox(height: 10),

                        // 4. BÁC SĨ NỔI BẬT (Gắn nguyên cục Component xịn sò vào đây)
                        const FeaturedDoctors(),

                        const SizedBox(
                          height: 30,
                        ), // Khoảng cách chừa dưới cùng
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // LỚP TRÊN CÙNG: Bong bóng Bác sĩ AI lơ lửng và kéo thả được
          const FloatingAIBubble(),
        ],
      ),
    );
  }
}
