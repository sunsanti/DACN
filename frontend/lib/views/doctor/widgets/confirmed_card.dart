import 'package:flutter/material.dart';

class ConfirmedCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final Color primaryDark;
  final Color accentBlue;
  final Color lightBG;
  final VoidCallback onCompleted;

  const ConfirmedCard({
    super.key,
    required this.schedule,
    required this.primaryDark,
    required this.accentBlue,
    required this.lightBG,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
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
                      schedule['name'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule['type'],
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_month, size: 14, color: accentBlue),
                        const SizedBox(width: 4),
                        Text(
                          "${schedule['time']} - ${schedule['date']}",
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
          const SizedBox(height: 12),
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
          const Divider(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCompleted,
              icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              label: const Text("Đã khám xong", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDark,
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