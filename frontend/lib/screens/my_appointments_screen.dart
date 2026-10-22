import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/billing_ui.dart';
import '../core/ui.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import 'ai_report_screen.dart';
import 'appointment_detail_screen.dart';

/// Filters on "Lịch hẹn của tôi". Also used by the home bubbles to open a pre-filtered list.
enum AppointmentFilter {
  all('Tất cả'),
  upcoming('Sắp tới'),
  unpaid('Chờ thanh toán'),
  examined('Đã khám'),
  canceled('Đã hủy');

  final String label;
  const AppointmentFilter(this.label);

  bool test(Appointment a) => switch (this) {
        all => true,
        upcoming => (a.isPending || a.isConfirmed) && a.apTime.isAfter(DateTime.now()),
        unpaid => a.hasBill && !a.isPaid,
        examined => a.isExamined,
        canceled => a.isCanceled,
      };
}

class MyAppointmentsScreen extends StatefulWidget {
  final AppointmentFilter initialFilter;
  const MyAppointmentsScreen({super.key, this.initialFilter = AppointmentFilter.all});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  late AppointmentFilter _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final list = provider.appointments.where(_filter.test).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch hẹn của tôi')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                for (final f in AppointmentFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: f == _filter,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<AppointmentProvider>().load(),
              child: provider.loading && provider.appointments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null && provider.appointments.isEmpty
                      ? EmptyState(Icons.cloud_off, 'Lỗi tải dữ liệu:\n${provider.error}')
                      : list.isEmpty
                          ? const EmptyState(Icons.event_available, 'Không có lịch khám nào.')
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              children: [
                                for (final a in list)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: AppointmentTile(a),
                                  ),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Patient-side appointment card (moved from the old home list).
class AppointmentTile extends StatelessWidget {
  final Appointment a;
  const AppointmentTile(this.a, {super.key});

  @override
  Widget build(BuildContext context) {
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
              if (a.hasBill) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Text('Cần thanh toán ${fmtMoney(a.payable!)}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  PaymentChip(a),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
