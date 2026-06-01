import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String _selectedFilter = 'Tất cả'; // 'Tất cả', 'Hôm nay', 'Tuần này', 'Chọn ngày'
  DateTime? _customSelectedDate; 
  String _searchQuery = ''; 

  // --- TRẠNG THÁI DỮ LIỆU THẬT ---
  List<Map<String, dynamic>> _patients = []; 
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPatientsFromAPI();
  }

  // --- HÀM KẾT NỐI API NESTJS ---
  Future<void> _fetchPatientsFromAPI() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Thay bằng ID bác sĩ thật đang đăng nhập của bạn (Ở JSON bạn gửi là doctorId: 2)
      int doctorId = 2; 

      // 💡 Lưu ý đổi lại thành 10.0.2.2 nếu bạn test lại trên LDPlayer mà 192.168.56.1 không chạy
      final url = Uri.parse('http://192.168.56.1:3000/doctor/list-appointment/$doctorId');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> rawData = json.decode(response.body);

        // 💡 Tạm thời lấy hết dữ liệu để hiển thị (Bạn có thể thêm .where((item) => item['confirmCondition'] == 0) nếu cần)
        final followUpData = rawData;

        // Chuyển đổi JSON sang cấu trúc Flutter cần
        List<Map<String, dynamic>> mappedPatients = followUpData.map((item) {
          // Xử lý ngày giờ
          DateTime apTime = DateTime.parse(item['apTime']).toLocal();
          String dateStr = "${apTime.day.toString().padLeft(2, '0')}/${apTime.month.toString().padLeft(2, '0')}/${apTime.year}";
          String timeStr = "${apTime.hour.toString().padLeft(2, '0')}:${apTime.minute.toString().padLeft(2, '0')}";

          // Lấy object bệnh nhân
          final patientRelation = item['patient'] ?? {};
          
          // Xử lý giới tính (JSON trả về "Gender.female" hoặc "Gender.male")
          String genderRaw = patientRelation['gender']?.toString() ?? '';
          String gender = 'Khác';
          if (genderRaw.toLowerCase().contains('female')) {
            gender = 'Nữ';
          } else if (genderRaw.toLowerCase().contains('male')) {
            gender = 'Nam';
          }

          String phone = patientRelation['phone'] ?? 'Không có SĐT';
          String age = patientRelation['age']?.toString() ?? '?';
          
          return {
            "id": patientRelation['id'] != null ? "BN-${patientRelation['id']}" : "BN-???",
            "name": patientRelation['name'] ?? "Chưa rõ tên",
            "info": "$gender, $age tuổi, SĐT: $phone", // Gom Giới tính, Tuổi và SĐT
            "lastVisit": dateStr, 
            "timeSlot": timeStr,  
            "lastDiagnosis": item['note'] ?? "Không có ghi chú.", // Lấy note (AI Chẩn đoán)
            "avatar": patientRelation['avatar'], // Trích xuất luôn link avatar
          };
        }).toList();

        setState(() {
          _patients = mappedPatients;
          _isLoading = false;
        });
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu: $e';
      });
      print("LỖI GỌI API: $e");
    }
  }

  // Hàm chuyển đổi String "DD/MM/YYYY" sang DateTime
  DateTime _parseDate(String dateStr) {
    List<String> parts = dateStr.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  // Hàm hiển thị DatePicker
  Future<void> _selectCustomDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

  // Hàm lọc danh sách
  List<Map<String, dynamic>> _getFilteredPatients() {
    DateTime now = DateTime.now(); 
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    List<Map<String, dynamic>> tempPatients = _patients.where((p) {
      DateTime visitDate = _parseDate(p['lastVisit']);
      DateTime cleanVisitDate = DateTime(visitDate.year, visitDate.month, visitDate.day);
      DateTime cleanNow = DateTime(now.year, now.month, now.day);

      if (_selectedFilter == 'Hôm nay') {
        return cleanVisitDate.isAtSameMomentAs(cleanNow);
      } else if (_selectedFilter == 'Tuần này') {
        return cleanVisitDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            cleanVisitDate.isBefore(cleanNow.add(const Duration(days: 1)));
      } else if (_selectedFilter == 'Chọn ngày' && _customSelectedDate != null) {
        DateTime cleanCustom = DateTime(_customSelectedDate!.year, _customSelectedDate!.month, _customSelectedDate!.day);
        return cleanVisitDate.isAtSameMomentAs(cleanCustom);
      }
      return true;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      tempPatients = tempPatients.where((p) {
        final name = p['name'].toString().toLowerCase();
        final id = p['id'].toString().toLowerCase();
        final info = p['info'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || id.contains(query) || info.contains(query);
      }).toList();
    }

    return tempPatients;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedPatients = _getFilteredPatients();

    displayedPatients.sort(
      (a, b) => _parseDate(b['lastVisit']).compareTo(_parseDate(a['lastVisit'])),
    );

    return Scaffold(
      backgroundColor: lightBG,
      appBar: AppBar(
        title: const Text(
          "Danh sách hẹn khám",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchPatientsFromAPI,
          )
        ],
      ),
      body: Column(
        children: [
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
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
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

          _buildFilterRow(),
          _buildSummaryCard(displayedPatients.length),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? _buildErrorWidget()
                    : displayedPatients.isEmpty
                        ? _buildEmptyWidget()
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

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchPatientsFromAPI,
              icon: const Icon(Icons.replay_rounded),
              label: const Text("Thử lại"),
              style: ElevatedButton.styleFrom(backgroundColor: primaryDark, foregroundColor: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
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
            "Không tìm thấy bệnh nhân nào\nphù hợp.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

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
          ActionChip(
            backgroundColor: _selectedFilter == 'Chọn ngày' ? primaryDark : Colors.white,
            side: BorderSide(
              color: _selectedFilter == 'Chọn ngày' ? primaryDark : Colors.grey.shade300,
            ),
            label: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: _selectedFilter == 'Chọn ngày' ? Colors.white : primaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  _customSelectedDate != null && _selectedFilter == 'Chọn ngày'
                      ? "${_customSelectedDate!.day}/${_customSelectedDate!.month}/${_customSelectedDate!.year}"
                      : "Chọn ngày",
                  style: TextStyle(
                    color: _selectedFilter == 'Chọn ngày' ? Colors.white : Colors.grey.shade700,
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

  Widget _buildSummaryCard(int totalPatients) {
    String timeText = _selectedFilter;
    if (_selectedFilter == 'Chọn ngày' && _customSelectedDate != null) {
      timeText = "ngày ${_customSelectedDate!.day}/${_customSelectedDate!.month}/${_customSelectedDate!.year}";
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
                        "lịch hẹn",
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
                // Thay vì hiển thị chữ cái đầu, code này ưu tiên hiển thị Avatar nếu có link
                patient['avatar'] != null && patient['avatar'].toString().startsWith('http')
                    ? CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(patient['avatar']),
                        backgroundColor: primaryDark.withOpacity(0.05),
                      )
                    : CircleAvatar(
                        radius: 25,
                        backgroundColor: primaryDark.withOpacity(0.05),
                        child: Text(
                          patient['name'].isNotEmpty ? patient['name'].substring(0, 1) : "?",
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          "Thông tin chẩn đoán (AI / Ghi chú):",
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
                            height: 1.4, // Tạo khoảng cách dòng cho text nhiều
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
                  "Lịch hẹn: ${patient['lastVisit']} lúc ${patient['timeSlot']}",
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