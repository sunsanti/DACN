import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 🌟 ĐÃ THÊM: Đảm bảo gói này đã được cài đặt trong pubspec.yaml

class CompletedCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final Color primaryDark;
  final Color accentBlue;
  // 🌟 ĐÃ SỬA: Thay đổi callback để truyền đầy đủ Ngày, Giờ, và Ghi chú về màn hình cha
  final Function(String date, String time, String note) onFollowUpScheduled;

  const CompletedCard({
    super.key,
    required this.schedule,
    required this.primaryDark,
    required this.accentBlue,
    required this.onFollowUpScheduled,
  });

  // 🌟 THÊM MỚI: Hàm hỗ trợ mở link PDF bệnh án AI
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

  // 🌟 THÊM MỚI: Hàm hiển thị Popup Dialog nhập thông tin tái khám
  void _showFollowUpDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7)); // Mặc định gợi ý tái khám sau 1 tuần
    TimeOfDay selectedTime = const TimeOfDay(hour: 09, minute: 00); // Mặc định gợi ý lúc 9:00 sáng
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc chọn hoặc bấm Hủy
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Định dạng hiển thị chuỗi ngày giờ trên giao diện popup
            String formattedDate = "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}";
            String formattedTime = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.edit_calendar, color: accentBlue),
                  const SizedBox(width: 8),
                  Text("Lên lịch tái khám", style: TextStyle(color: primaryDark, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bệnh nhân: ${schedule['name'] ?? 'Bệnh nhân chưa rõ'}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Divider(height: 20),
                    
                    // 1. Chọn ngày tái khám
                    const Text("Chọn ngày hẹn mới:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2027),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Icon(Icons.calendar_today, size: 18, color: accentBlue),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Chọn giờ tái khám
                    const Text("Chọn giờ hẹn mới:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Icon(Icons.access_time, size: 18, color: accentBlue),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. Nhập ghi chú đánh tay
                    const Text("Kết quả khám & Lời dặn:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "VD: Kết quả phục hồi tốt, dặn dò uống thuốc đúng cử, tái khám kiểm tra lại vết mổ...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Hủy bỏ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    
                    // Chuẩn hóa dữ liệu sang string định dạng YYYY-MM-DD và HH:mm để gửi lên Backend
                    String apiDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                    String apiTime = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
                    String apiNote = noteController.text.trim();

                    // Bắn dữ liệu về màn hình cha xử lý gọi API
                    onFollowUpScheduled(apiDate, apiTime, apiNote);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Xác nhận hẹn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy link hồ sơ AI từ object đồng bộ xuống
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule['name'] ?? 'Bệnh nhân chưa rõ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule['type'] ?? 'Khám bệnh',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Hoàn thành",
                  style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          
          // 🌟 THÊM MỚI: Khối hiển thị nút xem Hồ sơ bệnh án AI nếu ca khám này có đính kèm file
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
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // 🌟 ĐÃ SỬA: Khi bấm nút sẽ mở popup dialog thay vì chỉ mở date picker cũ
              onPressed: () => _showFollowUpDialog(context),
              icon: const Icon(Icons.edit_calendar, color: Colors.white, size: 18),
              label: const Text("Hẹn lịch tái khám", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}