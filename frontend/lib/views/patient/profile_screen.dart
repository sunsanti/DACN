import 'package:flutter/material.dart';

// --- ĐỊNH NGHĨA CLASS PATIENT Ở ĐÂY ĐỂ APP HIỂU ---
class Patient {
  final int id;
  String name;
  String gender; // 'male' | 'female'
  int age;
  DateTime birthDate;
  String email;
  String phone;
  String address;
  String avatar;
  String cccd;
  String bhyt;

  Patient({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.birthDate,
    required this.email,
    required this.phone,
    required this.address,
    required this.avatar,
    required this.cccd,
    required this.bhyt,
  });
}

// --- GIAO DIỆN MÀN HÌNH CHÍNH ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Giả lập trạng thái đăng nhập (đổi thành true nếu muốn thấy hồ sơ luôn)
  bool isLoggedIn = false;

  // Giả lập dữ liệu Patient lấy từ Backend
  Patient? myProfile = Patient(
    id: 1,
    name: "Nguyễn Văn Quý",
    gender: 'male',
    age: 25,
    birthDate: DateTime(1999, 10, 20),
    email: "quy.nguyen@email.com",
    phone: "0901234567",
    address: "123 Đường ABC, Quận 1, TP.HCM",
    avatar: "https://i.pravatar.cc/150?u=quy",
    cccd: "079099001234",
    bhyt: "GD479123456789",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text(
          "Hồ sơ cá nhân",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: isLoggedIn
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.teal),
                  onPressed: () {
                    /* Chuyển sang màn hình chỉnh sửa */
                  },
                ),
              ]
            : null,
      ),
      body: isLoggedIn ? _buildProfileUI() : _buildLoginRequiredUI(),
    );
  }

  // --- GIAO DIỆN KHI CHƯA ĐĂNG NHẬP ---
  Widget _buildLoginRequiredUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              // ĐÃ SỬA LỖI: BoxType thành BoxShape
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Bạn chưa đăng nhập",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Vui lòng đăng nhập để xem hồ sơ bệnh án, lịch hẹn và quản lý thông tin sức khỏe cá nhân.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => setState(
                () => isLoggedIn = true,
              ), // Giả lập bấm đăng nhập thành công
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "ĐĂNG NHẬP NGAY",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GIAO DIỆN HỒ SƠ CHI TIẾT ---
  Widget _buildProfileUI() {
    // ĐÃ SỬA LỖI: Lấy trực tiếp ngày/tháng/năm từ DateTime không cần thư viện intl
    String formattedDate =
        "${myProfile!.birthDate.day}/${myProfile!.birthDate.month}/${myProfile!.birthDate.year}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header: Avatar & Tên
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(myProfile!.avatar),
                    ),
                    // ĐÃ SỬA LỖI: PositionAt thành Positioned
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  myProfile!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Mã bệnh nhân: PN-${myProfile!.id}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Thông tin định danh
          _buildInfoSection("Thông tin định danh", [
            _buildInfoRow(Icons.badge_outlined, "Số CCCD", myProfile!.cccd),
            _buildInfoRow(
              Icons.health_and_safety_outlined,
              "Mã số BHYT",
              myProfile!.bhyt,
            ),
          ]),

          const SizedBox(height: 16),

          // Section 2: Thông tin cá nhân
          _buildInfoSection("Thông tin cá nhân", [
            _buildInfoRow(Icons.cake_outlined, "Ngày sinh", formattedDate),
            _buildInfoRow(
              Icons.wc_outlined,
              "Giới tính",
              myProfile!.gender == 'male' ? "Nam" : "Nữ",
            ),
            _buildInfoRow(
              Icons.phone_android_outlined,
              "Số điện thoại",
              myProfile!.phone,
            ),
            _buildInfoRow(Icons.email_outlined, "Email", myProfile!.email),
            _buildInfoRow(
              Icons.location_on_outlined,
              "Địa chỉ",
              myProfile!.address,
            ),
          ]),

          const SizedBox(height: 32),

          // Nút Đăng xuất
          TextButton.icon(
            onPressed: () => setState(() => isLoggedIn = false),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              "Đăng xuất tài khoản",
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
