import 'package:flutter/material.dart';
// Quý nhớ import đường dẫn tới file model của Quý vào đây nhé:
// import '../models/appointment.dart';
import '../../models/appointment_model.dart';
// import '../../models/patient_model.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  // --- GIẢ LẬP DỮ LIỆU TỪ BACKEND DỰA TRÊN MODEL CỦA QUÝ ---
  Future<List<Appointment>> fetchAppointmentsFromBackend() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    // Tạo danh sách dữ liệu dùng đúng class Appointment của Quý
    return [
      Appointment(
        id: 1,
        apTime: DateTime.now().add(
          const Duration(days: 2, hours: 3),
        ), // 2 ngày sau
        address: "Phòng 102 - Tòa nhà A, Bệnh viện X",
        note: "Khám lại dạ dày",
        confirmCondition: 0, // Chờ
        doctorName: "BS. Hà Văn Quyết",
        patientId: 101,
        doctorId: 201,
      ),
      Appointment(
        id: 2,
        apTime: DateTime.now().add(const Duration(days: 5, hours: 1)),
        address: "Phòng 205 - Tòa B",
        confirmCondition: 1, // Đã xác nhận
        doctorName: "BS. Nguyễn Thị Ngọc",
        patientId: 101,
        doctorId: 202,
      ),
      Appointment(
        id: 3,
        apTime: DateTime.now().subtract(const Duration(days: 1)), // Hôm qua
        address: "Phòng 102 - Tòa nhà A",
        confirmCondition: 2, // Hủy
        doctorName: "BS. Lê Văn Sỹ",
        patientId: 101,
        doctorId: 203,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Lịch hẹn của tôi",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: [
              Tab(text: "Chờ duyệt"), // confirmCondition = 0
              Tab(text: "Đã xác nhận"), // confirmCondition = 1
              Tab(text: "Đã hủy"), // confirmCondition = 2
            ],
          ),
        ),

        body: FutureBuilder<List<Appointment>>(
          future: fetchAppointmentsFromBackend(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            }

            final appointments = snapshot.data ?? [];

            // Lọc dữ liệu theo trạng thái confirmCondition của Quý
            final pending = appointments
                .where((a) => a.confirmCondition == 0)
                .toList();
            final confirmed = appointments
                .where((a) => a.confirmCondition == 1)
                .toList();
            final cancelled = appointments
                .where((a) => a.confirmCondition == 2)
                .toList();

            return TabBarView(
              children: [
                _buildAppointmentList(pending),
                _buildAppointmentList(confirmed),
                _buildAppointmentList(cancelled),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- GIAO DIỆN TỪNG THẺ LỊCH HẸN ---
  Widget _buildAppointmentList(List<Appointment> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "Không có lịch hẹn nào",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];

        // Tự động tách ngày và giờ từ apTime (DateTime)
        String dateStr =
            "${item.apTime.day.toString().padLeft(2, '0')}/${item.apTime.month.toString().padLeft(2, '0')}/${item.apTime.year}";
        String timeStr =
            "${item.apTime.hour.toString().padLeft(2, '0')}:${item.apTime.minute.toString().padLeft(2, '0')}";

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Dùng chữ cái đầu của tên bác sĩ làm Avatar vì model chưa có link ảnh
                  CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Text(
                      item.doctorName.replaceAll("BS. ", "")[0],
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.doctorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.address,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Colors.teal,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dateStr,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        color: Colors.teal,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        timeStr,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              // Hiển thị ghi chú nếu có
              if (item.note != null && item.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Ghi chú: ${item.note}",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
