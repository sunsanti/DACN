import 'package:flutter/material.dart';
import '../../../services/api_service.dart'; // Kiểm tra lại đường dẫn này

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
                      widget.schedule['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: widget.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.schedule['type'],
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
                      widget.schedule['time'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: widget.primaryDark,
                      ),
                    ),
                    Text(
                      widget.schedule['date'],
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
                      // Gọi callback kích hoạt setState ở màn hình cha
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

  Widget _buildPdfButton() {
    return InkWell(
      onTap: () {},
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
              style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}