import 'package:flutter/material.dart';
import 'booking_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  const DoctorDetailScreen({super.key});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  // Biến lưu trạng thái ngày và giờ được chọn
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;

  // Dữ liệu mẫu (Sau này có thể truyền từ trang chủ sang)
  final List<String> _dates = [
    "Hôm nay",
    "Ngày mai",
    "Thứ 4",
    "Thứ 5",
    "Thứ 6",
  ];
  final List<String> _times = [
    "08:00",
    "09:30",
    "10:00",
    "13:30",
    "15:00",
    "16:30",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Chi tiết Bác sĩ",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        ],
      ),
      // KHU VỰC NỘI DUNG CHÍNH CÓ THỂ CUỘN
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ), // Giữ form đẹp trên máy tính
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. THÔNG TIN CƠ BẢN CỦA BÁC SĨ
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh Bác sĩ
                    Hero(
                      tag: 'doctor_avatar',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          // THAY LINK ẢNH MỚI VÀO ĐÂY:
                          'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=500&auto=format&fit=crop&q=60',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          // Thêm hàm xử lý lỗi ảnh để nếu sau này link có chết thì nó hiện icon mặc định chứ không bị sọc vàng đen nữa
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Tên và chuyên khoa
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ThS. BS. Nguyễn Trần ABC",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Chuyên khoa Tim mạch - Bệnh viện Chợ Rẫy",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Sao đánh giá
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "4.9",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                " (120+ đánh giá)",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. CÁC CHỈ SỐ TIN CẬY
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      Icons.people_alt_outlined,
                      "Bệnh nhân",
                      "1000+",
                    ),
                    _buildStatCard(Icons.work_outline, "Kinh nghiệm", "10 Năm"),
                    _buildStatCard(Icons.star_border, "Đánh giá", "4.9"),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. GIỚI THIỆU
                const Text(
                  "Giới thiệu",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Bác sĩ Nguyễn Trần ABC là một trong những chuyên gia hàng đầu về phẫu thuật tim mạch tại Việt Nam. Với hơn 10 năm kinh nghiệm, bác sĩ đã cứu chữa thành công hàng ngàn ca bệnh phức tạp...",
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
                const SizedBox(height: 30),

                // 4. CHỌN NGÀY KHÁM
                const Text(
                  "Lịch khám",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedDateIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDateIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.teal : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.teal
                                  : Colors.grey.shade300,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            _dates[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 5. CHỌN GIỜ KHÁM (Lưới giờ)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 100,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _times.length,
                  itemBuilder: (context, index) {
                    bool isSelected = _selectedTimeIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTimeIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.teal.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Colors.teal
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          _times[index],
                          style: TextStyle(
                            color: isSelected ? Colors.teal : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 40,
                ), // Chừa khoảng trống cho nút Đặt lịch ở dưới
              ],
            ),
          ),
        ),
      ),

      // NÚT ĐẶT LỊCH GHIM Ở ĐÁY MÀN HÌNH
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ElevatedButton(
              onPressed: _selectedTimeIndex != -1
                  ? () {
                      // ĐÃ SỬA: Chuyển sang màn hình Form Đặt Lịch thay vì chỉ hiện thông báo
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookingScreen(
                            preSelectedDoctor:
                                "ThS. BS. Nguyễn Trần ABC", // Truyền tên bác sĩ
                            preSelectedSpecialty:
                                "Tim mạch - Bệnh viện Chợ Rẫy", // Truyền chuyên khoa
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "ĐẶT LỊCH NGAY",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget vẽ các ô Chỉ số (Bệnh nhân, Kinh nghiệm, Đánh giá)
  Widget _buildStatCard(IconData icon, String title, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.teal, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
