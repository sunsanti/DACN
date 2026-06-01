import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // Kiểm tra lại đường dẫn
import 'widgets/pending_card.dart';
import 'widgets/confirmed_card.dart';
import 'widgets/completed_card.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final Color primaryDark = const Color(0xFF03103F);
  final Color accentBlue = const Color(0xFF0084FF);
  final Color lightBG = const Color(0xFFF5F7F9);

  // 0: Đã xác nhận | 1: Chờ duyệt | 2: Đã khám
  int _selectedTab = 1; 

  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRealSchedules();
  }

  Future<void> _fetchRealSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      int loggedInDoctorId = 1; 

      final unacceptedData = await ApiService.getUnacceptedAppointments(loggedInDoctorId);
      final acceptedData = await ApiService.getAcceptedAppointments(loggedInDoctorId);

      List<Map<String, dynamic>> formattedSchedules = [];

      // Giữ nguyên logic gốc: Dùng chính vòng lặp để định nghĩa trạng thái 'pending' / 'confirmed'
      for (var item in unacceptedData) {
        formattedSchedules.add(_mapDataToUI(item, 'pending'));
      }

      for (var item in acceptedData) {
        formattedSchedules.add(_mapDataToUI(item, 'confirmed'));
      }

      setState(() {
        _schedules = formattedSchedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải dữ liệu từ máy chủ: $e';
        _isLoading = false;
      });
    }
  }

  // Giữ nguyên 100% hàm dịch dữ liệu gốc của bạn
  Map<String, dynamic> _mapDataToUI(dynamic item, String status) {
    String patientName = item['patientName'] ?? 'Bệnh nhân chưa rõ';
    
    if (item['patient'] != null && item['patient']['name'] != null) {
      patientName = item['patient']['name'];
    }

    String formattedTime = '--:--';
    String formattedDate = '--/--/----';
    
    if (item['apTime'] != null) {
      try {
        DateTime parsedDate = DateTime.parse(item['apTime']);
        formattedTime = "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
        formattedDate = "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
      } catch (e) {
        formattedTime = 'Lỗi giờ';
      }
    }

    return {
      'id': 'BN-${item['patientId'] ?? item['id'] ?? '??'}',
      'name': patientName,
      'type': item['note'] ?? 'Khám bệnh',
      'time': formattedTime,
      'date': formattedDate,
      'status': status,
      'note': item['note'] ?? '',
    };
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    int pendingCount = _schedules.where((s) => s['status'] == 'pending').length;

    // Lọc danh sách hiển thị
    List<Map<String, dynamic>> displayedList = _schedules.where((s) {
      if (_selectedTab == 0) return s['status'] == 'confirmed';
      if (_selectedTab == 1) return s['status'] == 'pending';
      return s['status'] == 'completed';
    }).toList();

    if (_selectedTab != 1) {
      displayedList.sort((a, b) {
        int dateCompare = a['date'].compareTo(b['date']);
        if (dateCompare != 0) return dateCompare;
        return a['time'].compareTo(b['time']);
      });
    }

    return Scaffold(
      backgroundColor: lightBG,
      appBar: AppBar(
        title: const Text(
          "Lịch hẹn của tôi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildSmartFilterTabs(pendingCount),

          Expanded(
            child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: primaryDark))
                : Column(
                    children: [
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Expanded(
                        child: displayedList.isEmpty
                            ? Center(
                                child: Text(
                                  _selectedTab == 0 ? "Chưa có lịch hẹn nào được xác nhận." :
                                  _selectedTab == 1 ? "Không có lịch hẹn nào đang chờ duyệt." : 
                                  "Chưa có bệnh nhân nào hoàn tất khám.",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: displayedList.length,
                                itemBuilder: (context, index) {
                                  final item = displayedList[index];
                                  
                                  if (_selectedTab == 1) {
                                    return PendingCard(
                                      schedule: item,
                                      primaryDark: primaryDark,
                                      accentBlue: accentBlue,
                                      lightBG: lightBG,
                                      onReject: () {
                                        setState(() {
                                          item['status'] = 'rejected';
                                        });
                                        _showToast("Đã từ chối lịch hẹn của ${item['name']}");
                                      },
                                      onConfirmSuccess: (updatedNote) {
                                        // Đồng bộ hóa trạng thái lên Widget cha để kích hoạt Re-render
                                        setState(() {
                                          item['note'] = updatedNote;
                                          item['status'] = 'confirmed';
                                        });
                                        _showToast("Đã duyệt lịch hẹn cho ${item['name']}");
                                      },
                                    );
                                  } else if (_selectedTab == 0) {
                                    return ConfirmedCard(
                                      schedule: item,
                                      primaryDark: primaryDark,
                                      accentBlue: accentBlue,
                                      lightBG: lightBG,
                                      onCompleted: () {
                                        setState(() {
                                          item['status'] = 'completed'; 
                                        });
                                        _showToast("Bệnh nhân ${item['name']} đã khám xong!");
                                      },
                                    );
                                  } else {
                                    return CompletedCard(
                                      schedule: item,
                                      primaryDark: primaryDark,
                                      accentBlue: accentBlue,
                                      onFollowUpScheduled: (pickedDate) {
                                        String formattedDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                        setState(() {
                                          _schedules.add({
                                            'id': 'BN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}', 
                                            'name': item['name'],
                                            'type': 'Tái khám (${item['type']})',
                                            'time': '09:00', 
                                            'date': formattedDate,
                                            'status': 'confirmed', 
                                            'note': 'Lịch hẹn tái khám từ ca khám ngày ${item['date']}.',
                                          });
                                          _selectedTab = 0; // Chuyển thẳng về Tab Đã xác nhận
                                        });
                                        _showToast("Đã tạo lịch hẹn tái khám ngày $formattedDate cho ${item['name']}!");
                                      },
                                    );
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Giữ nguyên UI của DateSelector từ file gốc
  Widget _buildDateSelector() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, index) {
          bool isSelected = index == 0;
          return Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
            decoration: BoxDecoration(
              color: isSelected ? primaryDark : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "T${index + 2}",
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${index + 10}",
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Giữ nguyên UI của SmartFilterTabs từ file gốc
  Widget _buildSmartFilterTabs(int pendingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryDark.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            _buildTabItem(0, "Đã xác nhận"),
            _buildTabItem(1, "Chờ duyệt", badgeCount: pendingCount),
            _buildTabItem(2, "Đã khám"),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title, {int badgeCount = 0}) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSelected ? primaryDark : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -8,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}