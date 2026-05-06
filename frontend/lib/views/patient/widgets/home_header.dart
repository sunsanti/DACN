import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String patientName;
  final String avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onFilterTap;
  final Function(String)? onSearchChanged;

  const HomeHeader({
    super.key,
    required this.patientName,
    required this.avatarUrl,
    this.onNotificationTap,
    this.onFilterTap,
    this.onSearchChanged,
  });

  // Hàm tính toán lời chào theo thời gian thực
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
      // Tách biệt padding rõ ràng để tạo khoảng thở (Whitespace) cho UI sang trọng
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.withOpacity(0.12),
            Colors.teal.withOpacity(0.02),
            const Color(0xFFF8FBFB),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HÀNG 1: MINI LOGO & THÔNG BÁO ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mini Logo Brand tinh tế
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.teal,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "MedAI Assistant",
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              // Nút thông báo Premium
              _buildNotificationBell(),
            ],
          ),
          const SizedBox(height: 20),

          // --- HÀNG 2: THÔNG TIN PATIENT (BACKEND WILL FILL HERE) ---
          Row(
            children: [
              // Avatar có vòng trạng thái (Status Ring) của tài khoản
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.teal, Colors.teal.shade200],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                  ),
                  // Chấm xanh nhỏ biểu thị tài khoản đang Online/Đang hoạt động
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Lời chào và tên hiển thị bứt phá về Typo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800, // Đậm hơn để nổi bật tên
                        color: Color(0xFF1A1C1E),
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- HÀNG 3: THANH TÌM KIẾM CÓ NÚT BỘ LỌC (FILTER) HIGH-TECH ---
          Row(
            children: [
              // Ô tìm kiếm chiếm đa số diện tích
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      16,
                    ), // Bo góc kiểu iOS mượt hơn
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Colors.teal,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: onSearchChanged,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: "Tìm bác sĩ, chuyên khoa, dịch vụ...",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nút FILTER nâng tầm giao diện
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Gọn gàng hóa code: Tách widget Chuông thông báo
  Widget _buildNotificationBell() {
    return InkWell(
      onTap: onNotificationTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1A1C1E),
              size: 22,
            ),
          ),
          // Chấm đỏ thông báo được thiết kế nhỏ gọn và tinh xảo hơn
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
