import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final Color primaryDark;

  const DateSelector({super.key, required this.primaryDark});

  @override
  Widget build(BuildContext context) {
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
          bool isSelected = index == 0; // Giữ nguyên logic UI cũ của bạn
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
}