import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  // Chỉ cần truyền Tên và Link Avatar từ Database vào đây
  final String patientName;
  final String avatarUrl;

  const HomeHeader({
    super.key,
    required this.patientName,
    required this.avatarUrl,
  });

  // --- BỘ MÀU CHUẨN ---
  final Color primaryDark = const Color(0xFF03103F);
  final Color gradientLight = const Color(0xFF103A8E);
  final Color accentBlue = const Color(0xFF0084FF);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Cân đối lại padding sau khi đã gỡ bỏ bớt các thành phần
      padding: const EdgeInsets.only(top: 48, left: 20, right: 20, bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryDark, gradientLight],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HÀNG 1: MINI LOGO ---
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "MedAI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // --- HÀNG 2: THÔNG TIN NGƯỜI DÙNG (LUÔN ĐĂNG NHẬP) ---
          _buildLoggedInUser(),
        ],
      ),
    );
  }

  // --- WIDGET: HIỂN THỊ THÔNG TIN ---
  Widget _buildLoggedInUser() {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accentBlue, Colors.blue.shade200],
                ),
              ),
              child: CircleAvatar(
                radius: 22, 
                backgroundColor: primaryDark,
                // Nếu avatarUrl trống, hiện icon mặc định. Ngược lại thì load ảnh từ mạng.
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty 
                    ? const Icon(Icons.person, color: Colors.white) 
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400, // Chấm xanh online
                  shape: BoxShape.circle,
                  border: Border.all(color: gradientLight, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12, 
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                patientName.isNotEmpty ? patientName : "Bệnh nhân", // Xử lý nếu tên trống
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}