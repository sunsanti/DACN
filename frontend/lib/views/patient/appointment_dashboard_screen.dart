import 'package:flutter/material.dart';
import 'booking_screen.dart'; // Đảm bảo Quý đã import form đặt lịch

class AppointmentDashboardScreen extends StatefulWidget {
  const AppointmentDashboardScreen({super.key});

  @override
  State<AppointmentDashboardScreen> createState() =>
      _AppointmentDashboardScreenState();
}

class _AppointmentDashboardScreenState extends State<AppointmentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Dữ liệu mẫu lịch hẹn
  final List<Map<String, dynamic>> _appointments = [
    {
      "doctor": "ThS. BS. Nguyễn Trần ABC",
      "specialty": "Tim mạch",
      "date": "15 Tháng 6, 2024",
      "time": "09:30 AM",
      "status": "Confirmed", // Trạng thái: Confirmed, Pending, Cancelled
      "id": "PME-8821",
    },
    {
      "doctor": "PGS. TS. Lê Văn Minh",
      "specialty": "Cơ Xương Khớp",
      "date": "20 Tháng 6, 2024",
      "time": "14:00 PM",
      "status": "Pending",
      "id": "PME-9012",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Lịch hẹn của tôi",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.teal,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Sắp diễn ra"),
            Tab(text: "Lịch sử khám"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: DANH SÁCH LỊCH SẮP TỚI
          _buildAppointmentList(isHistory: false),
          // TAB 2: DANH SÁCH LỊCH SỬ (Tạm thời để trống)
          _buildAppointmentList(isHistory: true),
        ],
      ),
      // NÚT BẤM NỔI "ĐẶT LỊCH MỚI"
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Khi nhấn vào sẽ mở Form đặt lịch trống
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookingScreen()),
          );
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Đặt lịch mới",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAppointmentList({required bool isHistory}) {
    // Lọc dữ liệu (Đây là demo nên mình chỉ hiện danh sách mẫu)
    if (isHistory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "Chưa có lịch sử khám bệnh",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final item = _appointments[index];
        return _buildAppointmentCard(item);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> item) {
    Color statusColor;
    String statusText;

    switch (item['status']) {
      case 'Confirmed':
        statusColor = Colors.green;
        statusText = "Đã xác nhận";
        break;
      case 'Pending':
        statusColor = Colors.orange;
        statusText = "Đang chờ duyệt";
        break;
      default:
        statusColor = Colors.red;
        statusText = "Đã hủy";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "ID: ${item['id']}",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['doctor'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    item['specialty'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: Colors.teal.shade300,
              ),
              const SizedBox(width: 8),
              Text(item['date'], style: const TextStyle(fontSize: 14)),
              const Spacer(),
              Icon(
                Icons.access_time_rounded,
                size: 18,
                color: Colors.teal.shade300,
              ),
              const SizedBox(width: 8),
              Text(item['time'], style: const TextStyle(fontSize: 14)),
            ],
          ),
          if (item['status'] == 'Confirmed') ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Mở QR Code hoặc chi tiết vé khám
              },
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: const Text("XEM VÉ KHÁM"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade50,
                foregroundColor: Colors.teal,
                elevation: 0,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
