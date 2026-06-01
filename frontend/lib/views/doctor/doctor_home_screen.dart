import 'package:flutter/material.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  // --- BỘ MÀU THEME CHUẨN ---
  final Color primaryDark = const Color(0xFF03103F);
  final Color accentBlue = const Color(0xFF0084FF);
  final Color lightBG = const Color(0xFFF5F7F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBG,
      // APPBAR NAVY ĐỒNG BỘ
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=11',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Chào buổi sáng,",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const Text(
                  "BS. Trần Văn A",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('3'), // Báo hiệu có thông báo mới
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN 1: TỔNG QUAN TIẾN ĐỘ HÔM NAY ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tiến độ hôm nay",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
                Text(
                  "15 Tháng 5, 2026",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Đã khám",
                    "05",
                    Icons.check_circle_rounded,
                    const Color(0xFF10B981), // Xanh lá
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    "Đang chờ",
                    "07",
                    Icons.hourglass_bottom_rounded,
                    const Color(0xFFF59E0B), // Cam
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    "Lịch mới",
                    "03",
                    Icons.calendar_month_rounded,
                    accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- PHẦN 2: CA KHÁM HIỆN TẠI / TIẾP THEO ---
            Text(
              "Ca khám tiếp theo",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildNextPatientCard(),

            const SizedBox(height: 32),

            // --- PHẦN 3: LỊCH TRÌNH SẮP TỚI (Mini Timeline) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Lịch trình sắp tới",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Chuyển sang Tab Lịch hẹn
                  },
                  child: Text(
                    "Xem toàn bộ",
                    style: TextStyle(
                      color: accentBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            _buildUpcomingScheduleCard(
              "09:00 AM",
              "Lê Thị B",
              "Tái khám huyết áp",
              true,
            ),
            _buildUpcomingScheduleCard(
              "09:30 AM",
              "Trần Văn C",
              "Tư vấn dinh dưỡng",
              false,
            ),
            _buildUpcomingScheduleCard(
              "10:00 AM",
              "Nguyễn Thu D",
              "Đọc kết quả xét nghiệm",
              false,
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: THẺ THỐNG KÊ NHANH ---
  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: CA KHÁM TIẾP THEO (GÂY CHÚ Ý NHẤT) ---
  Widget _buildNextPatientCard() {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ), // Giảm nhẹ padding từ 20 xuống 16 để tăng không gian
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryDark, const Color(0xFF0F267A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // THAY ĐỔI Ở ĐÂY: Dùng Wrap + SizedBox dể tự động xuống dòng khi màn hình hẹp
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8, // Khoảng cách giữa các dòng nếu bị rớt dòng
              spacing: 8, // Khoảng cách giữa các phần tử trên cùng hàng
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentBlue.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize
                        .min, // Đảm bảo Row không chiếm hết chiều ngang
                    children: [
                      Icon(
                        Icons.meeting_room_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Phòng khám 102",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "08:30 AM (Đang chờ)",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Text(
                  "H",
                  style: TextStyle(
                    color: primaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                // Đảm bảo text không đẩy văng widget khác
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hoàng Trọng C.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Nam • 45 tuổi • Mã: BN-1092",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.monitor_heart_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Lý do: Khám tổng quát, đau nhẹ vùng ngực.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              "BẮT ĐẦU KHÁM",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: LỊCH TRÌNH SẮP TỚI ---
  Widget _buildUpcomingScheduleCard(
    String time,
    String name,
    String reason,
    bool isNext,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNext ? accentBlue.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time.split(' ')[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryDark,
                  ),
                ),
                Text(
                  time.split(' ')[1],
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: isNext ? accentBlue : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
