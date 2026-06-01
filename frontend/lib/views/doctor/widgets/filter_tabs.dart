import 'package:flutter/material.dart';

class FilterTabs extends StatelessWidget {
  final int selectedTab;
  final int pendingCount;
  final Color primaryDark;
  final ValueChanged<int> onTabChanged;

  const FilterTabs({
    super.key,
    required this.selectedTab,
    required this.pendingCount,
    required this.primaryDark,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Container(
        height: 48,
        // Dùng ListView để thanh tab có thể vuốt ngang nếu 4 tab quá dài so với màn hình nhỏ
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryDark.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabItem(0, "Chờ duyệt", badgeCount: pendingCount), // Tab 0
                  _buildTabItem(1, "Đã xác nhận"),                         // Tab 1
                  _buildTabItem(2, "Đã khám xong"),                        // Tab 2
                  _buildTabItem(3, "Hẹn tái khám"),                        // Tab 3
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title, {int badgeCount = 0}) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 22,
                  minHeight: 22,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}