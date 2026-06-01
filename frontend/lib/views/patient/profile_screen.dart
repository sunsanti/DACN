import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IMPORT CÁC FILE ĐỂ LẤY MODEL VÀ GỌI API
import '../../models/patient_model.dart';
import '../../services/api_service.dart';

// IMPORT MÀN HÌNH CHỈNH SỬA VÀ ĐĂNG NHẬP
import 'widgets/edit_profile_screen.dart'; 
import 'login_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoggedIn = false;
  Patient? myProfile;
  bool isLoading = true; 

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetchProfile(); // Tự động check trạng thái khi mở màn hình
  }

  // Kiểm tra trạng thái đăng nhập từ SharedPreferences trước khi gọi API
  Future<void> _checkLoginAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    bool status = prefs.getBool('isLoggedIn') ?? false;
    int? savedId = prefs.getInt('patientId');

    if (status && savedId != null) {
      if (mounted) {
        setState(() {
          isLoggedIn = true;
        });
      }
      _fetchPatientProfile(savedId); // Có ID thật thì đi gọi API
    } else {
      if (mounted) {
        setState(() {
          isLoggedIn = false;
          isLoading = false; // Tắt loading để hiện UI yêu cầu đăng nhập
        });
      }
    }
  }

  // HÀM KÉO DỮ LIỆU TỪ NESTJS VỀ FLUTTER (Ép tạo khung trống nếu tài khoản mới tinh 🚀)
  Future<void> _fetchPatientProfile(int targetId) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      // Gọi API lấy thông tin bệnh nhân theo ID người đang đăng nhập
      final profile = await ApiService.getPatientProfile(targetId);
      
      if (mounted) {
        setState(() {
          if (profile != null) {
            myProfile = profile; // Có dữ liệu cũ thì lấy dữ liệu cũ
          } else {
            myProfile = _createEmptyProfile(targetId); // Tài khoản mới tinh chưa nhập liệu
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Kể cả khi API trả về lỗi 404, vẫn ép tạo khung trống để cứu giao diện và hiện nút Edit
          myProfile = _createEmptyProfile(targetId);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // HÀM TẠO HỒ SƠ TRỐNG MẶC ĐỊNH CHO TÀI KHOẢN MỚI (ĐÃ FIX LỖI AGE)
  Patient _createEmptyProfile(int id) {
    return Patient(
      id: id,
      name: "Người dùng mới", 
      avatar: "",             
      age: 0, // Đã thêm trường age bắt buộc để sửa lỗi gạch đỏ
      cccd: "",
      bhyt: "",
      birthDate: DateTime.now(), 
      gender: Gender.male,       
      phone: "",
      email: "",
      address: "",
    );
  }

  // HÀM XỬ LÝ ĐĂNG XUẤT THẬT SỰ
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa sạch bộ nhớ tạm (token, id, đăng nhập)

    if (mounted) {
      // Đá thẳng người dùng ra màn hình Đăng nhập và xóa lịch sử các trang trước
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        title: const Text(
          "Hồ sơ cá nhân",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // NÚT ĐĂNG XUẤT VÀ CHỈNH SỬA TRÊN THANH APP BAR (VỊ TRÍ 1)
        actions: isLoggedIn
            ? [
                if (myProfile != null)
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Colors.blue, size: 28),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(patient: myProfile!),
                        ),
                      );
                      if (result == true) {
                        _fetchPatientProfile(myProfile!.id); // Reload dữ liệu sau khi sửa thành công
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red), // Nút Đăng xuất trên AppBar
                  onPressed: _handleLogout,
                ),
              ]
            : null,
      ),
      // ĐÃ TỐI ƯU ĐIỀU KIỆN HIỂN THỊ: Không còn bị kẹt ở màn hình lỗi nữa!
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) 
          : !isLoggedIn
              ? _buildLoginRequiredUI() 
              : _buildProfileUI(), // Đã đăng nhập là bắt buộc hiện giao diện hồ sơ
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
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: Colors.blue,
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
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "ĐĂNG NHẬP NGAY",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GIAO DIỆN HỒ SƠ CHI TIẾT ---
  Widget _buildProfileUI() {
    if (myProfile == null) return const Center(child: Text("Đang khởi tạo dữ liệu..."));

    String formattedDate =
        "${myProfile!.birthDate.day}/${myProfile!.birthDate.month}/${myProfile!.birthDate.year}";

    return RefreshIndicator(
      onRefresh: () => _fetchPatientProfile(myProfile!.id), 
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: myProfile!.avatar.startsWith('http')
                            ? NetworkImage(myProfile!.avatar)
                            : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Mã bệnh nhân: PN-${myProfile!.id}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildInfoSection("Thông tin định danh", [
              _buildInfoRow(Icons.badge_outlined, "Số CCCD", myProfile!.cccd ?? ""), // Đã sửa lỗi Null-safety
              _buildInfoRow(
                Icons.health_and_safety_outlined,
                "Mã số BHYT",
                myProfile!.bhyt ?? "", // Đã sửa lỗi Null-safety
              ),
            ]),

            const SizedBox(height: 16),

            _buildInfoSection("Thông tin cá nhân", [
              _buildInfoRow(Icons.cake_outlined, "Ngày sinh", myProfile!.name == "Người dùng mới" ? "" : formattedDate),
              _buildInfoRow(
                Icons.wc_outlined,
                "Giới tính",
                myProfile!.name == "Người dùng mới" ? "" : (myProfile!.gender == Gender.male ? "Nam" : "Nữ"), 
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

            // NÚT ĐĂNG XUẤT CHỮ ĐỎ DƯỚI CÙNG (VỊ TRÍ 2)
            TextButton.icon(
              onPressed: _handleLogout, 
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                "Đăng xuất tài khoản",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue),
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
                  value.trim().isEmpty ? "Chưa cập nhật" : value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}