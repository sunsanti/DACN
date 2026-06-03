import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../core/pdf_opener.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/doctor_provider.dart';
import '../services/doctor_service.dart';
import 'doctor_shifts_screen.dart';

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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _confirm(Appointment a) async {
    final provider = context.read<DoctorProvider>();
    final noteCtrl = TextEditingController(text: a.note ?? '');
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

  Future<void> _reschedule(Appointment a) async {
    final provider = context.read<DoctorProvider>();
    DateTime newDate = a.apTime;
    TimeOfDay newTime = TimeOfDay.fromDateTime(a.apTime);
    final noteCtrl = TextEditingController(text: a.note ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Đổi lịch #${a.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: ctx,
                          initialDate: newDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (p != null) setLocal(() => newDate = p);
                      },
                      child: Text('${newDate.day}/${newDate.month}/${newDate.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final p = await showTimePicker(context: ctx, initialTime: newTime);
                        if (p != null) setLocal(() => newTime = p);
                      },
                      child: Text(newTime.format(ctx)),
                    ),
                  ),
                ],
              ),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final newApTime = DateTime(newDate.year, newDate.month, newDate.day, newTime.hour, newTime.minute);
    try {
      await provider.reschedule(
            a.id,
            newApTime: newApTime,
            newConfirmTime: DateTime.now(),
            newNote: noteCtrl.text.trim(),
          );
      _toast('Đã đổi lịch #${a.id}');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
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

  Future<void> _deleteAppt(Appointment a) async {
    final provider = context.read<DoctorProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xoá lịch #${a.id}?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _docService.deleteAppointment(a.id);
      await provider.load();
      _toast('Đã xoá lịch #${a.id}');
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bác sĩ — Lịch hẹn'),
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
          bottom: TabBar(tabs: [
            Tab(text: 'Chờ xác nhận (${provider.pending.length})'),
            Tab(text: 'Đã xác nhận (${provider.confirmed.length})'),
          ]),
        ),
        body: provider.loading && provider.pending.isEmpty && provider.confirmed.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _list(provider.pending, pending: true),
                  _list(provider.confirmed, pending: false),
                ],
              ),
      ),
    );
  }

  Widget _list(List<Appointment> items, {required bool pending}) {
    return RefreshIndicator(
      onRefresh: () => context.read<DoctorProvider>().load(),
      child: items.isEmpty
          ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Trống'))])
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _tile(items[i], pending: pending),
            ),
    );
  }

  Widget _tile(Appointment a, {required bool pending}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lịch #${a.id} — ${_fmt(a.apTime)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Bệnh nhân: ${a.patientName}'),
            Text('Địa chỉ: ${a.address}'),
            if (a.note != null && a.note!.isNotEmpty) Text('Ghi chú: ${a.note}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (pending)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Xác nhận'),
                    onPressed: () => _confirm(a),
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  label: const Text('Đổi lịch'),
                  onPressed: () => _reschedule(a),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.description, size: 18),
                  label: const Text('Báo cáo AI'),
                  onPressed: () => _openReport(a),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('Xoá', style: TextStyle(color: Colors.red)),
                  onPressed: () => _deleteAppt(a),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
