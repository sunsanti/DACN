import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../../services/api_service.dart'; 

class PendingCard extends StatefulWidget {
  final Map<String, dynamic> schedule;
  final Color primaryDark;
  final Color accentBlue;
  final Color lightBG;
  final VoidCallback onReject;
  final Function(String updatedNote) onConfirmSuccess;

  const PendingCard({
    super.key,
    required this.schedule,
    required this.primaryDark,
    required this.accentBlue,
    required this.lightBG,
    required this.onReject,
    required this.onConfirmSuccess,
  });

  @override
  State<PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<PendingCard> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.schedule['note']?.toString() ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // 🚀 LOGIC ĐÃ ĐỒNG BỘ CHUẨN VỚI BÊN BỆNH NHÂN
  Future<void> _openPdfFile() async {
    debugPrint("🔍 [DOCTOR DATA DEBUG]: ${widget.schedule.toString()}");
    
    // Ưu tiên kiểm tra key chuẩn 'aiDiagnosticPdf' trước, sau đó là 'pdfUrl'
    String? pdfPath = widget.schedule['aiDiagnosticPdf']?.toString() ?? widget.schedule['pdfUrl']?.toString();

    // 1. Kiểm tra nếu ca khám này chưa có file PDF
    if (pdfPath == null || pdfPath.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Ca khám này hiện chưa có file PDF hoặc link bệnh án!'), 
            backgroundColor: Colors.orange
          ),
        );
      }
      return;
    }

    String path = pdfPath.trim();
    String fullUrl = "";
    
    // 2. Tự động kiểm tra cấu trúc đường dẫn link
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // Nếu là link tuyệt đối hoàn chỉnh -> Giữ nguyên
      fullUrl = path;
    } else {
      // Nếu là đường dẫn tương đối nội bộ -> Chuẩn hóa dấu gạch chéo và nối với IP Backend
      String baseUrl = "http://192.168.56.1:3000"; 
      if (!path.startsWith('/')) {
        path = '/$path';
      }
      fullUrl = "$baseUrl$path";
    }

    // Thông báo trạng thái xử lý cho Bác sĩ
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đang tải hồ sơ bệnh án của: ${widget.schedule['name']}"),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    final Uri url = Uri.parse(fullUrl);

    try {
      // Kích hoạt LaunchMode.externalApplication đẩy trực tiếp ra trình duyệt/hệ thống Android tự xử lý
      bool canLaunch = await launchUrl(url, mode: LaunchMode.externalApplication);
      
      if (!canLaunch && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Không thể mở PDF. Vui lòng cài đặt Trình duyệt hoặc ứng dụng đọc PDF!"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi hệ thống không thể mở tệp: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accentBlue.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: widget.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: widget.accentBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.schedule['name'] ?? 'Bệnh nhân',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: widget.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.schedule['type'] ?? 'Khám bệnh',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ), 
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.lightBG,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.schedule['time'] ?? '--:--',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: widget.primaryDark,
                      ),
                    ),
                    Text(
                      widget.schedule['date'] ?? '--/--/----',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Nút bấm mở PDF thông minh 
          _buildPdfButton(),
          
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: "Nhập ghi chú sau khi xem hồ sơ...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              filled: true,
              fillColor: widget.lightBG,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: widget.onReject,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "TỪ CHỐI",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    String rawId = widget.schedule['id'].toString().replaceAll('BN-', '');
                    int appointmentId = int.tryParse(rawId) ?? 0;

                    if (appointmentId == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lỗi: Không tìm thấy ID hợp lệ!")),
                      );
                      return;
                    }

                    bool success = await ApiService.confirmAppointment(
                      appointmentId, 
                      _noteController.text.isEmpty ? 'Đã duyệt' : _noteController.text,
                    );

                    if (success) {
                      widget.onConfirmSuccess(_noteController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lỗi: Không thể xác nhận trên máy chủ!")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "XÁC NHẬN",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget thiết kế nút PDF đồng bộ màu đỏ sang trọng của file cũ
  Widget _buildPdfButton() {
    return InkWell(
      onTap: _openPdfFile, 
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 16),
            const SizedBox(width: 6),
            Text(
              "Xem hồ sơ chẩn đoán (PDF)",
              style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}