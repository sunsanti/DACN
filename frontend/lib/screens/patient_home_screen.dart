import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import 'create_appointment_screen.dart';
import 'ai_report_screen.dart';
import 'appointment_detail_screen.dart';
import 'profile_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch khám của tôi'),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ',
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateAppointmentScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Đặt lịch'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppointmentProvider>().load(),
        child: _body(provider),
      ),
    );
  }

  Widget _body(AppointmentProvider provider) {
    if (provider.loading && provider.appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.appointments.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text('Lỗi tải dữ liệu:\n${provider.error}', textAlign: TextAlign.center)),
        ],
      );
    }
    if (provider.appointments.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Chưa có lịch khám.\nNhấn "Đặt lịch" để tạo.', textAlign: TextAlign.center)),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: provider.appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _tile(provider.appointments[i]),
    );
  }

  Widget _tile(Appointment a) {
    final d = a.apTime;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event)),
        title: Text('BS. ${a.doctorName} — $dateStr'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Địa chỉ: ${a.address}'),
            if (a.note != null && a.note!.isNotEmpty) Text('Ghi chú: ${a.note}'),
            if (a.doctorNote != null && a.doctorNote!.isNotEmpty)
              Text('BS: ${a.doctorNote}', style: const TextStyle(color: Colors.blue)),
            Text('Trạng thái: ${a.statusLabel}',
                style: TextStyle(
                    color: a.isCanceled
                        ? Colors.red
                        : a.isConfirmed
                            ? Colors.green
                            : a.isExamined
                                ? Colors.blue
                                : Colors.orange)),
            if (a.isCanceled && a.cancelReason != null)
              Text('Lý do hủy: ${a.cancelReason}', style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        trailing: a.isCanceled
            ? null
            : IconButton(
                tooltip: 'Gửi ảnh + triệu chứng cho AI',
                icon: const Icon(Icons.smart_toy),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AiReportScreen(appointment: a)),
                ),
              ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointmentId: a.id)),
        ),
      ),
    );
  }
}
