import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../core/pdf_opener.dart';
import '../core/reason_dialog.dart';
import '../core/billing_ui.dart';
import '../core/ui.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/doctor_provider.dart';
import '../services/doctor_service.dart';
import 'doctor_shifts_screen.dart';
import 'doctor_appointment_detail_screen.dart';
import 're_examination_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final _docService = DoctorService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().load();
    });
  }

  Future<void> _confirm(Appointment a) async {
    final provider = context.read<DoctorProvider>();
    final noteCtrl = TextEditingController(text: a.doctorNote ?? '');
    DateTime confirmDate = DateTime.now();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận lịch #${a.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú cho bệnh nhân'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await provider.confirm(a.id, note: noteCtrl.text.trim(), confirmDate: confirmDate);
      _toast('Đã xác nhận lịch #${a.id}');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _cancelByDoctor(Appointment a, String title) async {
    final provider = context.read<DoctorProvider>();
    final reason = await promptReason(context,
        title: title, hint: 'Lý do (gửi cho bệnh nhân)', confirmLabel: 'Xác nhận');
    if (reason == null) return;
    try {
      await provider.cancelByDoctor(a.id, reason);
      _toast('Đã gửi tới bệnh nhân');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _rescheduleDoctor(Appointment a) async {
    if (a.doctorId == null) return;
    final provider = context.read<DoctorProvider>();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Chọn ngày dời lịch',
    );
    if (date == null || !mounted) return;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    List<DateTime> slots;
    try {
      slots = await _docService.availability(a.doctorId!, dateStr);
    } catch (e) {
      _toast(DioClient.messageFrom(e));
      return;
    }
    if (!mounted) return;
    if (slots.isEmpty) {
      _toast('Bạn chưa có khung trống ngày này (đăng ký ca trước)');
      return;
    }
    final slot = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Chọn khung giờ mới'),
        children: slots
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s),
                  child: Text(
                      '${s.day}/${s.month} — ${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}'),
                ))
            .toList(),
      ),
    );
    if (slot == null) return;
    try {
      await provider.reschedule(a.id, slot.toUtc().toIso8601String());
      _toast('Đã dời lịch #${a.id}');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _complete(Appointment a) async {
    final provider = context.read<DoctorProvider>();
    final ids = await pickDiseases(context);
    if (ids == null) return;
    try {
      await provider.complete(a.id, ids);
      _toast('Đã đánh dấu khám xong lịch #${a.id}');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _reExam(Appointment a) async {
    if (a.patientId == null || a.doctorId == null) {
      _toast('Thiếu thông tin bệnh nhân');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReExaminationScreen(
          doctorId: a.doctorId!,
          patientId: a.patientId!,
          patientName: a.patientName,
          defaultAddress: a.address,
        ),
      ),
    );
  }

  Future<void> _openReport(Appointment a) async {
    try {
      final pdf = await _docService.downloadReport(a.id);
      final path = await openPdf(pdf, 'report-${a.id}.pdf');
      _toast(path != null ? 'Đã mở báo cáo' : 'Đã tải báo cáo (xem ở tab mới/Downloads)');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorProvider>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const SessionTitle('Lịch hẹn của tôi'),
          actions: [
            IconButton(
              tooltip: 'Ca trực',
              icon: const Icon(Icons.schedule),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DoctorShiftsScreen()),
              ),
            ),
            IconButton(
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
          bottom: TabBar(isScrollable: true, tabs: [
            Tab(text: 'Chờ (${provider.pending.length})'),
            Tab(text: 'Đã xác nhận (${provider.confirmed.length})'),
            Tab(text: 'Đã khám (${provider.completed.length})'),
          ]),
        ),
        body: provider.loading &&
                provider.pending.isEmpty &&
                provider.confirmed.isEmpty &&
                provider.completed.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _list(provider.pending),
                  _list(provider.confirmed),
                  _list(provider.completed),
                ],
              ),
      ),
    );
  }

  Widget _list(List<Appointment> items) {
    return RefreshIndicator(
      onRefresh: () => context.read<DoctorProvider>().load(),
      child: items.isEmpty
          ? const EmptyState(Icons.inbox_outlined, 'Không có lịch hẹn nào')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _tile(items[i]),
            ),
    );
  }

  Widget _tile(Appointment a) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DoctorAppointmentDetailScreen(appointmentId: a.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(a.patientName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  StatusChip(a),
                ],
              ),
              InfoLine(Icons.schedule, '${fmtDateTime(a.apTime)}  ·  Lịch #${a.id}'),
              InfoLine(Icons.place_outlined, a.address),
              if (a.note != null && a.note!.isNotEmpty) InfoLine(Icons.notes, a.note!),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (a.isPending)
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Xác nhận'),
                      onPressed: () => _confirm(a),
                    ),
                  if (a.isConfirmed)
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.task_alt, size: 18),
                      label: const Text('Đã khám xong'),
                      onPressed: () => _complete(a),
                    ),
                  if (a.isConfirmed && a.canReschedule)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: const Text('Dời lịch'),
                      onPressed: () => _rescheduleDoctor(a),
                    ),
                  if (a.isExamined)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event_repeat, size: 18),
                      label: const Text('Tái khám'),
                      onPressed: () => _reExam(a),
                    ),
                  if (!a.isExamined)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.description, size: 18),
                      label: const Text('Báo cáo AI'),
                      onPressed: () => _openReport(a),
                    ),
                  if (a.isPending)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.block, size: 18, color: Colors.red),
                      label: const Text('Không nhận bệnh', style: TextStyle(color: Colors.red)),
                      onPressed: () => _cancelByDoctor(a, 'Không nhận bệnh #${a.id}'),
                    ),
                  if (a.isConfirmed)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                      label: const Text('Hủy lịch', style: TextStyle(color: Colors.red)),
                      onPressed: () => _cancelByDoctor(a, 'Hủy lịch #${a.id}'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
