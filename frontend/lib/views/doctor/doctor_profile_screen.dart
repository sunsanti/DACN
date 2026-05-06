import 'package:flutter/material.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  // Trạng thái bật/tắt nhận lịch hẹn trực tuyến của bác sĩ
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text(
          "Hồ sơ bác sĩ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- HEADER: AVATAR & TÊN BÁC SĨ ---
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=11',
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "BS. Trần Văn A",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Chuyên khoa: Tim mạch",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- TRẠNG THÁI LÀM VIỆC (QUICK TOGGLE) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: _isAvailable ? Colors.green : Colors.grey,
                        size: 12,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isAvailable ? "Đang nhận lịch hẹn" : "Đang tạm nghỉ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isAvailable,
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- KHỐI THÔNG TIN HÀNH NGHỀ ---
            _buildSectionTitle("Thông tin hành nghề"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildProfileRow(
                    Icons.assignment_ind_outlined,
                    "Mã số CCHN",
                    "CCHN-001234",
                  ),
                  _buildProfileRow(
                    Icons.local_hospital_outlined,
                    "Nơi làm việc",
                    "Bệnh viện Chợ Rẫy",
                  ),
                  _buildProfileRow(
                    Icons.workspace_premium_outlined,
                    "Kinh nghiệm",
                    "10 năm kinh nghiệm",
                  ),
                  _buildProfileRow(
                    Icons.payments_outlined,
                    "Giá khám",
                    "300.000 đ / lượt",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- KHỐI CÀI ĐẶT LỊCH LÀM VIỆC ---
            _buildSectionTitle("Cấu hình & Tài khoản"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildClickableRow(
                    Icons.access_time,
                    "Cài đặt khung giờ khám",
                  ),
                  _buildClickableRow(
                    Icons.lock_outline,
                    "Đổi mật khẩu tài khoản",
                  ),
                  _buildClickableRow(Icons.help_outline, "Hỗ trợ kỹ thuật"),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- NÚT ĐĂNG XUẤT ---
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                "Đăng xuất tài khoản",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget: Tiêu đề từng nhóm thông tin
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // Widget: Hàng hiển thị thông tin chữ (không bấm được)
  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 22),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Widget: Hàng có mũi tên (bấm được để mở tính năng khác)
  Widget _buildClickableRow(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade400, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade400,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
