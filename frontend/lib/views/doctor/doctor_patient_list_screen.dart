import 'package:flutter/material.dart';

class DoctorPatientListScreen extends StatefulWidget {
  const DoctorPatientListScreen({super.key});

  @override
  State<DoctorPatientListScreen> createState() =>
      _DoctorPatientListScreenState();
}

class _DoctorPatientListScreenState extends State<DoctorPatientListScreen> {
  // --- BỘ MÀU THEME ---
  final Color primaryDark = const Color(0xFF03103F);
  final Color accentBlue = const Color(0xFF0084FF);
  final Color lightBG = const Color(0xFFF5F7F9);

  // --- TRẠNG THÁI LỌC ---
  String _selectedFilter =
      'Tất cả'; // 'Tất cả', 'Hôm nay', 'Tuần này', 'Chọn ngày'
  DateTime? _customSelectedDate; // Lưu ngày do người dùng tự chọn

  // --- DỮ LIỆU MÔ PHỎNG ---
  // Mình đã chỉnh ngày về gần hiện tại (tháng 5/2026) để test bộ lọc
  final List<Map<String, dynamic>> _patients = [
    {
      "id": "BN-1029",
      "name": "Nguyễn Văn Quý",
      "info": "Nam, 25 tuổi",
      "lastVisit": "07/05/2026", // Hôm nay (Giả lập)
      "lastDiagnosis": "Viêm phế quản cấp, ho nhiều về đêm.",
    },
    {
      "id": "BN-1030",
      "name": "Trần Thị Bé",
      "info": "Nữ, 32 tuổi",
      "lastVisit": "05/05/2026", // Trong tuần này
      "lastDiagnosis": "Rối loạn tiêu hóa, trào ngược dạ dày.",
    },
    {
      "id": "BN-0984",
      "name": "Lê Văn Cường",
      "info": "Nam, 45 tuổi",
      "lastVisit": "01/05/2026",
      "lastDiagnosis": "Tăng huyết áp vô căn.",
    },
    {
      "id": "BN-0762",
      "name": "Hoàng Thu Hà",
      "info": "Nữ, 28 tuổi",
      "lastVisit": "20/11/2025", // Cũ
      "lastDiagnosis": "Viêm da cơ địa, dị ứng thời tiết.",
    },
  ];

  // Hàm chuyển đổi String "DD/MM/YYYY" sang DateTime
  DateTime _parseDate(String dateStr) {
    List<String> parts = dateStr.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  // Hàm hiển thị DatePicker để chọn ngày cụ thể
  Future<void> _selectCustomDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryDark,
              onPrimary: Colors.white,
              onSurface: primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilter = 'Chọn ngày';
        _customSelectedDate = picked;
      });
    }
  }

  // Hàm lọc danh sách dựa trên _selectedFilter
  List<Map<String, dynamic>> _getFilteredPatients() {
    DateTime now = DateTime.now(); // Lấy ngày hiện tại
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    return _patients.where((p) {
      DateTime visitDate = _parseDate(p['lastVisit']);
      // Loại bỏ giờ/phút/giây để so sánh ngày chính xác
      DateTime cleanVisitDate = DateTime(
        visitDate.year,
        visitDate.month,
        visitDate.day,
      );
      DateTime cleanNow = DateTime(now.year, now.month, now.day);

      if (_selectedFilter == 'Hôm nay') {
        return cleanVisitDate.isAtSameMomentAs(cleanNow);
      } else if (_selectedFilter == 'Tuần này') {
        return cleanVisitDate.isAfter(
              startOfWeek.subtract(const Duration(days: 1)),
            ) &&
            cleanVisitDate.isBefore(cleanNow.add(const Duration(days: 1)));
      } else if (_selectedFilter == 'Chọn ngày' &&
          _customSelectedDate != null) {
        DateTime cleanCustom = DateTime(
          _customSelectedDate!.year,
          _customSelectedDate!.month,
          _customSelectedDate!.day,
        );
        return cleanVisitDate.isAtSameMomentAs(cleanCustom);
      }
      return true; // 'Tất cả'
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedPatients = _getFilteredPatients();

    // Luôn sắp xếp Mới nhất lên đầu
    displayedPatients.sort(
      (a, b) =>
          _parseDate(b['lastVisit']).compareTo(_parseDate(a['lastVisit'])),
    );

    return Scaffold(
      backgroundColor: lightBG,
      appBar: AppBar(
        title: const Text(
          "Bệnh nhân đã khám",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Tìm tên, SĐT hoặc mã BN...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: accentBlue),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // 2. KHU VỰC BỘ LỌC THỜI GIAN
          _buildFilterRow(),

          // 3. THẺ TỔNG HỢP THÔNG TIN (SUMMARY)
          _buildSummaryCard(displayedPatients.length),

          // 4. DANH SÁCH BỆNH NHÂN
          Expanded(
            child: displayedPatients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Không có bệnh nhân nào\ntrong khoảng thời gian này.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayedPatients.length,
                    itemBuilder: (context, index) {
                      return _buildPatientCard(displayedPatients[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: THANH LỌC THỜI GIAN ---
  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildFilterChip('Tất cả'),
          const SizedBox(width: 8),
          _buildFilterChip('Hôm nay'),
          const SizedBox(width: 8),
          _buildFilterChip('Tuần này'),
          const SizedBox(width: 8),

          // Nút Chọn ngày (DatePicker)
          ActionChip(
            backgroundColor: _selectedFilter == 'Chọn ngày'
                ? primaryDark
                : Colors.white,
            side: BorderSide(
              color: _selectedFilter == 'Chọn ngày'
                  ? primaryDark
                  : Colors.grey.shade300,
            ),
            label: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: _selectedFilter == 'Chọn ngày'
                      ? Colors.white
                      : primaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  _customSelectedDate != null && _selectedFilter == 'Chọn ngày'
                      ? "${_customSelectedDate!.day}/${_customSelectedDate!.month}/${_customSelectedDate!.year}"
                      : "Chọn ngày",
                  style: TextStyle(
                    color: _selectedFilter == 'Chọn ngày'
                        ? Colors.white
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            onPressed: () => _selectCustomDate(context),
          ),
        ],
      ),
    );
  }

  // Hàm hỗ trợ vẽ từng cục Filter
  Widget _buildFilterChip(String title) {
    bool isSelected = _selectedFilter == title;
    return ChoiceChip(
      label: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: primaryDark,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? primaryDark : Colors.grey.shade300),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = title;
          });
        }
      },
    );
  }

  // --- WIDGET: THẺ TỔNG HỢP ---
  Widget _buildSummaryCard(int totalPatients) {
    String timeText = _selectedFilter;
    if (_selectedFilter == 'Chọn ngày' && _customSelectedDate != null) {
      timeText =
          "ngày ${_customSelectedDate!.day}/${_customSelectedDate!.month}/${_customSelectedDate!.year}";
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryDark, const Color(0xFF0F267A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tổng quan ($timeText)",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$totalPatients",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        "lượt khám",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: THẺ BỆNH NHÂN (Giữ nguyên như bản nâng cấp trước) ---
  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đang mở hồ sơ của ${patient['name']}...")),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: primaryDark.withOpacity(0.05),
                  child: Text(
                    patient['name'].substring(0, 1),
                    style: TextStyle(
                      color: primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patient['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              patient['id'],
                              style: TextStyle(
                                fontSize: 10,
                                color: accentBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient['info'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey.shade400,
                    size: 14,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 1),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_information,
                    size: 18,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Chẩn đoán lần trước:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patient['lastDiagnosis'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.history, size: 14, color: accentBlue),
                const SizedBox(width: 4),
                Text(
                  "Ngày khám: ${patient['lastVisit']}",
                  style: TextStyle(
                    color: accentBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
