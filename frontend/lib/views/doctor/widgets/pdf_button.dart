import 'package:flutter/material.dart';

class PdfButton extends StatelessWidget {
  const PdfButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đang tải dữ liệu và mở PDF Hồ sơ bệnh án..."),
            duration: Duration(seconds: 2),
          ),
        );
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