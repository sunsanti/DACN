import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  // Biến này để nhận biết: Có truyền tên bác sĩ từ màn hình Chi tiết sang không?
  final String? preSelectedDoctor;
  final String? preSelectedSpecialty;

  const BookingScreen({
    super.key,
    this.preSelectedDoctor,
    this.preSelectedSpecialty,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Dữ liệu Form
  final TextEditingController _nameController = TextEditingController(
    text: "Nguyễn Văn Bệnh Nhân",
  ); // Giả lập đã có hồ sơ
  final TextEditingController _phoneController = TextEditingController(
    text: "0987654321",
  );
  final TextEditingController _symptomController = TextEditingController();

  String? _selectedSpecialty;
  String? _selectedDoctor;

  // Quản lý ngày giờ
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;

  final List<String> _dates = [
    "Hôm nay",
    "Ngày mai",
    "10/06",
    "11/06",
    "12/06",
  ];

  // Cấu trúc giờ: kèm trạng thái isAvailable (Còn trống hay đã Bận)
  final List<Map<String, dynamic>> _times = [
    {"time": "08:00", "isAvailable": false}, // false = Đã có người đặt
    {"time": "09:00", "isAvailable": true},
    {"time": "10:00", "isAvailable": false},
    {"time": "13:30", "isAvailable": true},
    {"time": "14:30", "isAvailable": true},
    {"time": "16:00", "isAvailable": true},
  ];

  @override
  void initState() {
    super.initState();
    // Nếu có bác sĩ truyền sang, gán luôn vào form
    _selectedSpecialty = widget.preSelectedSpecialty;
    _selectedDoctor = widget.preSelectedDoctor;
  }

  void _submitBooking() {
    if (_selectedTimeIndex == -1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn giờ khám!')));
      return;
    }

    // Hiển thị Dialog (Popup) báo thành công giống các bệnh viện lớn
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text("Gửi yêu cầu thành công!"),
        content: const Text(
          "Hệ thống đã ghi nhận lịch hẹn của bạn. Tổng đài viên sẽ gọi điện lại trong vòng 15 phút để xác nhận chính xác.\n\nCảm ơn bạn đã tin tưởng!",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Đóng Dialog
                Navigator.pop(context); // Quay về trang trước
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text(
                "Về trang chủ",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPreSelected = widget.preSelectedDoctor != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          "Đăng ký khám bệnh",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PHẦN 1: THÔNG TIN DỊCH VỤ / BÁC SĨ ---
                _buildSectionTitle("1. Thông tin dịch vụ"),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Nếu đã chọn từ Profile Bác sĩ -> Khóa lại không cho đổi. Nếu từ Trang chủ -> Hiện Dropdown
                      isPreSelected
                          ? _buildLockedField(
                              "Bác sĩ phụ trách",
                              _selectedDoctor!,
                            )
                          : _buildDropdown("Chọn chuyên khoa (Tùy chọn)", [
                              "Khám tổng quát",
                              "Tim mạch",
                              "Nhi khoa",
                              "Da liễu",
                            ]),

                      const SizedBox(height: 16),

                      isPreSelected
                          ? _buildLockedField(
                              "Chuyên khoa",
                              _selectedSpecialty!,
                            )
                          : _buildDropdown("Chọn bác sĩ (Tùy chọn)", [
                              "Bác sĩ A",
                              "Bác sĩ B",
                              "Không chỉ định (Sắp xếp ngẫu nhiên)",
                            ]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- PHẦN 2: CHỌN NGÀY GIỜ ---
                _buildSectionTitle("2. Thời gian khám"),
                const Text(
                  "Giờ hiển thị màu xám là giờ Bác sĩ đã có lịch.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Chọn ngày
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedDateIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDateIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.teal : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.teal
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            _dates[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Chọn giờ
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _times.length,
                  itemBuilder: (context, index) {
                    final timeSlot = _times[index];
                    bool isAvailable = timeSlot['isAvailable'];
                    bool isSelected = _selectedTimeIndex == index;

                    return GestureDetector(
                      onTap: isAvailable
                          ? () => setState(() => _selectedTimeIndex = index)
                          : null, // Không bấm được nếu bận
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !isAvailable
                              ? Colors
                                    .grey
                                    .shade200 // Màu xám nếu bận
                              : (isSelected
                                    ? Colors.teal.shade50
                                    : Colors.white), // Đổi màu nếu được chọn
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !isAvailable
                                ? Colors.transparent
                                : (isSelected
                                      ? Colors.teal
                                      : Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          timeSlot['time'],
                          style: TextStyle(
                            color: !isAvailable
                                ? Colors.grey
                                : (isSelected ? Colors.teal : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            decoration: !isAvailable
                                ? TextDecoration.lineThrough
                                : null, // Gạch ngang giờ đã bận
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- PHẦN 3: THÔNG TIN BỆNH NHÂN ---
                _buildSectionTitle("3. Thông tin bệnh nhân"),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Họ và tên người khám",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: "Số điện thoại liên hệ",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _symptomController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Mô tả triệu chứng / Lý do khám",
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ElevatedButton(
              onPressed: _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "GỬI YÊU CẦU ĐẶT LỊCH",
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  // Giao diện ô khóa (Không cho chỉnh sửa)
  Widget _buildLockedField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // Giao diện ô thả xuống
  Widget _buildDropdown(String hint, List<String> items) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (value) {},
    );
  }
}
