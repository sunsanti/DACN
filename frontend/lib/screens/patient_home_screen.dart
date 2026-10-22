import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/news_ui.dart';
import '../core/ui.dart';
import '../models/news.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../services/news_service.dart';
import 'ai_report_screen.dart';
import 'create_appointment_screen.dart';
import 'my_appointments_screen.dart';
import 'paid_bills_screen.dart';
import 'profile_screen.dart';

/// Patient home: news carousel + shortcut bubbles + news list. The appointment list lives in
/// [MyAppointmentsScreen].
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

  /// Push a screen, then reload so bubble badges reflect what changed there.
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) context.read<AppointmentProvider>().load();
  }

  /// "Báo cáo AI": pick one of the non-canceled appointments first.
  Future<void> _pickForAi() async {
    final list = context.read<AppointmentProvider>().appointments.where((a) => !a.isCanceled).toList();
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có lịch khám. Hãy đặt lịch trước.')),
      );
      return;
    }
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text('Chọn lịch khám để gửi cho AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              for (var i = 0; i < list.length; i++)
                ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text('BS. ${list[i].doctorName}'),
                  subtitle: Text('${fmtTime(list[i].apTime)}  ·  ${fmtDate(list[i].apTime)}'),
                  trailing: StatusChip(list[i]),
                  onTap: () => Navigator.pop(ctx, i),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) _open(AiReportScreen(appointment: list[picked]));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final appts = provider.appointments;
    final upcoming = appts.where(AppointmentFilter.upcoming.test).length;
    final unpaid = appts.where(AppointmentFilter.unpaid.test).length;

    final bubbles = [
      Bubble(Icons.edit_calendar, 'Đặt lịch khám',
          color: const Color(0xFF0E7C86), onTap: () => _open(const CreateAppointmentScreen())),
      Bubble(Icons.event_note, 'Lịch hẹn\ncủa tôi',
          color: const Color(0xFF3559C7),
          badge: upcoming,
          onTap: () => _open(const MyAppointmentsScreen())),
      Bubble(Icons.payments, 'Chờ\nthanh toán',
          color: const Color(0xFFB26B00),
          badge: unpaid,
          onTap: () => _open(const MyAppointmentsScreen(initialFilter: AppointmentFilter.unpaid))),
      Bubble(Icons.receipt_long, 'Hoá đơn\nđã trả',
          color: const Color(0xFF2E7D32), onTap: () => _open(const PaidBillsScreen())),
      Bubble(Icons.smart_toy, 'Báo cáo AI', color: const Color(0xFF7B3FC4), onTap: _pickForAi),
      Bubble(Icons.account_circle, 'Hồ sơ',
          color: const Color(0xFFC2364A), onTap: () => _open(const ProfileScreen())),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const SessionTitle('Trang chủ'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (_news.isNotEmpty) ...[
              NewsCarousel(_news.take(5).toList()),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisExtent: 122, // bubble + 2 label lines; fixed so wide screens don't stretch cells
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: bubbles,
                ),
              ),
            ),
            if (provider.error != null && appts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InfoLine(Icons.cloud_off, 'Lỗi tải lịch khám: ${provider.error}',
                    color: Colors.red.shade700),
              ),
            if (_news.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('Tin tức sức khoẻ', style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final n in _news) NewsTile(n),
            ],
          ],
        ),
      ),
    );
  }
}
