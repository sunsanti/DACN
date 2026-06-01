import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Đảm bảo bạn đã thêm gói này vào pubspec.yaml

class ConfirmedCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final Color primaryDark;
  final Color accentBlue;
  final Color lightBG;
  final VoidCallback onCompleted;
  final VoidCallback onMissed; 

  const ConfirmedCard({
    super.key,
    required this.schedule,
    required this.primaryDark,
    required this.accentBlue,
    required this.lightBG,
    required this.onCompleted,
    required this.onMissed, 
  });

  // Hàm hỗ trợ mở link PDF bệnh án
  Future<void> _openPdfUrl(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có tệp PDF đính kèm cho lịch hẹn này")),
      );
      return;
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Không thể mở liên kết';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi mở PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy link PDF được đồng bộ từ màn hình chính xuống
    final String? pdfUrl = schedule['aiDiagnosticPdf']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: primaryDark.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: primaryDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule['name'] ?? 'Bệnh nhân chưa rõ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule['type'] ?? 'Khám bệnh',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_month, size: 14, color: accentBlue),
                        const SizedBox(width: 4),
                        Text(
                          "${schedule['time'] ?? '--:--'} - ${schedule['date'] ?? '--/--/----'}",
                          style: TextStyle(color: accentBlue, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.phone, color: accentBlue, size: 22),
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: accentBlue.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          
          // Ghi chú của cuộc hẹn (nếu có)
          if ((schedule['note']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Ghi chú: ${schedule['note']}",
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 🌟 THÊM MỚI: Khối hiển thị nút xem Hồ sơ bệnh án AI mẫu PDF
          if (pdfUrl != null && pdfUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openPdfUrl(context, pdfUrl),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 18, color: accentBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Xem kết quả chẩn đoán hình ảnh (AI).pdf",
                        style: TextStyle(
                          color: accentBlue, 
                          fontWeight: FontWeight.w600, 
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 14, color: accentBlue),
                  ],
                ),
              ),
            ),
          ],

          const Divider(height: 24),
          
          // Thanh hành động phản hồi trạng thái buổi khám
          Row(
            children: [
              // Nút 1: Bệnh nhân vắng mặt (Trạng thái 3)
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: onMissed,
                  icon: const Icon(Icons.person_off_outlined, color: Colors.orange, size: 16),
                  label: const Text(
                    "Không đến",
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Nút 2: Khám hoàn tất (Trạng thái 2)
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: onCompleted,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                  label: const Text(
                    "Đã khám xong",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}