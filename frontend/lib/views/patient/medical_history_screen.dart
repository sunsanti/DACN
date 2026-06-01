import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // 🌟 THÊM: Mở link PDF bệnh án
import '../../services/api_service.dart';
import 'appointment_screen.dart'; // 🌟 THÊM: Điều hướng sang màn hình đặt lịch khi bấm tái khám

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  List<dynamic> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicalHistory();
  }

  Future<void> _loadMedicalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int patientId = prefs.getInt('patientId') ?? 1;

      // Gọi API lấy lịch hẹn chung
      final data = await ApiService.getPatientAppointments(patientId);
      
      if (mounted) {
        setState(() {
          // Lọc ra danh sách những lịch hẹn ĐÃ KHÁM XONG (confirmCondition == 3)
          _historyList = data.where((appt) => appt['confirmCondition'] == 3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải lịch sử bệnh án: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        title: const Text('Hồ Sơ Bệnh Án Chi Tiết', style: TextStyle(color: Color(0xFF03103F), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF03103F)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMedicalHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _historyList.length,
                    itemBuilder: (context, index) {
                      final record = _historyList[index];
                      return _buildHistoryCard(record);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa có hồ sơ bệnh án nào.',
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic record) {
    // Định dạng thời gian hiển thị gọn gàng hơn
    DateTime parsedTime = DateTime.tryParse(record['apTime']?.toString() ?? '') ?? DateTime.now();
    String formattedTime = "${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')} - ${parsedTime.day}/${parsedTime.month}/${parsedTime.year}";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00CC99).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF00CC99)),
        ),
        title: Text(
          'Bác sĩ: ${record['doctorName'] ?? 'Bác sĩ phụ trách'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF03103F)),
        ),
        subtitle: Text(
          '🗓️ Ngày khám: $formattedTime',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                _buildInfoRow(Icons.sick_outlined, "Triệu chứng ban đầu:", record['symptoms'] ?? 'Không ghi nhận'),
                const SizedBox(height: 10),
                
                _buildInfoRow(Icons.biotech_outlined, "Chẩn đoán bệnh:", record['diagnosis'] ?? 'Sức khỏe ổn định, theo dõi thêm'),
                const SizedBox(height: 10),

                _buildInfoRow(Icons.medication_liquid_sharp, "Đơn thuốc chỉ định:", record['prescription'] ?? 'Theo dõi thêm tại nhà'),
                const SizedBox(height: 16),

                // 🌟 THÊM: Kiểm tra và hiển thị nút mở file PDF cũ nếu có lưu trên Server
                if (record['aiDiagnosticPdf'] != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        String path = record['aiDiagnosticPdf']!;
                        String baseUrl = "http://192.168.56.1:3000"; // Đồng bộ IP với hệ thống của bạn
                        
                        if (!path.startsWith('/')) {
                          path = '/$path';
                        }
                        
                        final url = Uri.parse("$baseUrl$path");
                        try {
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('❌ Không có ứng dụng phù hợp để mở PDF!'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        } catch (e) {
                          debugPrint("Lỗi mở PDF bệnh án: $e");
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                      label: const Text(
                        "Xem Lại Phiếu Chẩn Đoán AI (.pdf)", 
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],

                const Divider(height: 20),

                // Khu vực Nhãn trạng thái & Nút Tái khám
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nhãn trạng thái hoàn thành cũ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00CC99).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "Đã hoàn thành",
                        style: TextStyle(color: Color(0xFF00CC99), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),

                    // 🌟 THÊM: Nút Đặt lịch tái khám thông minh
                    ElevatedButton.icon(
                      onPressed: () {
                        // Tạo thông tin tự động điền sẵn cho màn hình Đặt Lịch
                        String followUpNote = "🔄 [LỊCH HẸN TÁI KHÁM]\n- Khám lại từ đợt điều trị ngày: $formattedTime\n- Bác sĩ phụ trách cũ: ${record['doctorName'] ?? 'Không rõ'}\n- Chẩn đoán cũ: ${record['diagnosis'] ?? 'Chưa rõ'}";
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentScreen(
                              aiDiagnosisResult: followUpNote, // Đẩy thông tin bệnh án cũ vào mục dữ liệu tự động
                            ),
                          ),
                        ).then((_) => _loadMedicalHistory()); // Tải lại danh sách nếu có cập nhật gì mới khi quay về
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                      label: const Text("Tái khám", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF03103F).withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 2),
              Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF03103F), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}