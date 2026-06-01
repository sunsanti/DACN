import 'package:flutter/material.dart';

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF), // Tone xanh nhạt y tế
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Thông tin Bác sĩ",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Giữ form đẹp trên cả tablet/PC
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. THÔNG TIN CƠ BẢN CỦA BÁC SĨ (Ảnh, Tên, Chuyên khoa)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=500&auto=format&fit=crop&q=60',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.person, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 18),
                              const SizedBox(width: 4),
                              const Text(
                                "4.9",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                " (120+ đánh giá)",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. CÁC CHỈ SỐ UY TÍN (Bệnh nhân, Kinh nghiệm, Đánh giá)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(Icons.people_alt_outlined, "Bệnh nhân", "1000+"),
                    _buildStatCard(Icons.work_outline, "Kinh nghiệm", "10 Năm"),
                    _buildStatCard(Icons.star_border, "Đánh giá", "4.9"),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. ĐOẠN VĂN GIỚI THIỆU CHI TIẾT
                const Text(
                  "Giới thiệu chi tiết",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Bác sĩ Nguyễn Trần ABC là một trong những chuyên gia hàng đầu về phẫu thuật và điều trị các bệnh lý tim mạch tại Việt Nam. Với hơn 10 năm công tác tại các bệnh viện lớn, bác sĩ đã cứu chữa thành công hàng ngàn ca bệnh phức tạp và luôn nhận được sự tin yêu từ người bệnh.",
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 15),
                ),
                const SizedBox(height: 24),

                // 4. THÔNG TIN BỔ SUNG (Làm giả thông tin học vấn/kinh nghiệm cho đẹp trang)
                const Text(
                  "Kinh nghiệm & Học vấn",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildInfoRow("2018 - Nay:", "Phó khoa Tim mạch - Bệnh viện Chợ Rẫy"),
                _buildInfoRow("2015 - 2018:", "Bác sĩ điều trị - Khoa Tim mạch chuyên sâu"),
                _buildInfoRow("Học vị:", "Thạc sĩ Y khoa - Đại học Y Dược TP.HCM"),
                _buildInfoRow("Chứng chỉ:", "Tu nghiệp Phẫu thuật nội soi Tim mạch tại Pháp"),
              ],
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
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
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

  // Widget dòng thông tin phụ phụ
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}