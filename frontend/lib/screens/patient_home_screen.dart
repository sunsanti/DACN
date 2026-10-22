import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/news_ui.dart';
import '../core/ui.dart';
import '../models/appointment.dart';
import '../models/news.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../services/news_service.dart';
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
  List<News> _news = []; // empty or failed → news blocks are hidden

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final appts = context.read<AppointmentProvider>().load();
    try {
      final news = await NewsService().list(limit: 20);
      if (mounted) setState(() => _news = news);
    } catch (_) {
      // tin tức là phụ: lỗi thì ẩn, không chặn lịch khám
    }
    await appts;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const SessionTitle('Lịch khám của tôi'),
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
        onRefresh: _refresh,
        child: _body(provider),
      ),
    );
  }

  Widget _body(AppointmentProvider provider) {
    if (provider.loading && provider.appointments.isEmpty && _news.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final outline = Theme.of(context).colorScheme.outline;
    Widget message(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(children: [
            Icon(icon, size: 48, color: outline),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: outline)),
          ]),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (_news.isNotEmpty) ...[
          NewsCarousel(_news.take(5).toList()),
          const SizedBox(height: 20),
          _sectionTitle('Lịch khám của tôi'),
        ],
        if (provider.error != null && provider.appointments.isEmpty)
          message(Icons.cloud_off, 'Lỗi tải dữ liệu:\n${provider.error}')
        else if (provider.appointments.isEmpty)
          message(Icons.event_available, 'Chưa có lịch khám.\nNhấn "Đặt lịch" để tạo.')
        else
          for (final a in provider.appointments)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: _tile(a)),
        if (_news.isNotEmpty) ...[
          const SizedBox(height: 8),
          _sectionTitle('Tin tức sức khoẻ'),
          for (final n in _news) NewsTile(n),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _tile(Appointment a) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointmentId: a.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('BS. ${a.doctorName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  StatusChip(a),
                  if (!a.isCanceled)
                    IconButton(
                      tooltip: 'Gửi ảnh + triệu chứng cho AI',
                      icon: Icon(Icons.smart_toy_outlined, color: scheme.primary),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AiReportScreen(appointment: a)),
                      ),
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
              InfoLine(Icons.schedule, '${fmtTime(a.apTime)}  ·  ${fmtDate(a.apTime)}'),
              InfoLine(Icons.place_outlined, a.address),
              if (a.note != null && a.note!.isNotEmpty) InfoLine(Icons.notes, a.note!),
              if (a.doctorNote != null && a.doctorNote!.isNotEmpty)
                InfoLine(Icons.medical_information_outlined, 'BS: ${a.doctorNote}', color: scheme.primary),
              if (a.isCanceled && a.cancelReason != null)
                InfoLine(Icons.info_outline, 'Lý do hủy: ${a.cancelReason}', color: Colors.red.shade700),
            ],
          ),
        ),
      ),
    );
  }
}
