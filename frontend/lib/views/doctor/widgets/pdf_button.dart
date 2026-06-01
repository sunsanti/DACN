import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 🌟 Thư viện dùng để kích hoạt Google Drive

class PdfButton extends StatelessWidget {
  // 🌟 ĐÃ SỬA: Nhận dữ liệu của ca khám hiện tại để phân biệt từng bệnh nhân
  final Map<String, dynamic> schedule; 

  const PdfButton({super.key, required this.schedule});

  // Hàm xử lý kích hoạt app Google Drive / Trình duyệt trên máy ảo
  Future<void> _openPdfFile(BuildContext context) async {
    // Lấy ID gốc (ví dụ: BN-12 -> lấy ra số 12) nếu bạn muốn dùng ID để định danh file
    String rawId = schedule['id'].toString().replaceAll('BN-', '');

    // 🔗 CẤU HÌNH ĐƯỜNG LINK Ở ĐÂY:
    // Bạn hãy thay thế bằng link thư mục hoặc file PDF mẫu trên Google Drive của bạn
    String googleDriveUrl = "https://drive.google.com/file/d/1N_x9m6b9-p8_J9jP-VmLb-FkZ3H4aM_A/view?usp=sharing";

    // Mẹo chuyên sâu: Nếu sau này Backend của bạn trả về link PDF riêng cho mỗi ca khám, hãy viết thế này:
    // String googleDriveUrl = schedule['pdfUrl'] ?? "https://drive.google.com";

    final Uri url = Uri.parse(googleDriveUrl);

    try {
      // LaunchMode.externalApplication bắt buộc máy ảo phải dùng App ngoài (như Google Drive) để mở thay vì mở trong App của mình
      bool canLaunch = await launchUrl(url, mode: LaunchMode.externalApplication);
      
      if (!canLaunch) {
        if (context.mounted) {
          _showErrorSnackBar(context, "Không thể tìm thấy ứng dụng phù hợp để mở file PDF này.");
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, "Lỗi hệ thống không thể mở link: $e");
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đang mở PDF bệnh án của bệnh nhân: ${schedule['name']}"),
            duration: const Duration(seconds: 1),
          ),
        );
        
        // Gọi hàm mở PDF thực tế
        _openPdfFile(context);
      },
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
              "Xem hồ sơ (PDF)",
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}