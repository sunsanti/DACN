import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../core/reason_dialog.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../services/appointment_service.dart';
import 'ai_report_screen.dart';
import 'create_appointment_screen.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final int appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _service = AppointmentService();
  Appointment? _appt;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _appt = await _service.getAppointment(widget.appointmentId);
    } catch (e) {
      _error = DioClient.messageFrom(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _reschedule(Appointment a) async {
    if (a.doctorId == null) return;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Chọn ngày khám mới',
    );
    if (date == null || !mounted) return;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    List<DateTime> slots;
    try {
      slots = await _service.availability(a.doctorId!, dateStr);
    } catch (e) {
      _toast(DioClient.messageFrom(e));
      return;
    }
    if (!mounted) return;
    if (slots.isEmpty) {
      _toast('Bác sĩ chưa có khung trống ngày này');
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
      await _service.rescheduleAppointment(a.id, apTime: slot.toUtc().toIso8601String());
      if (mounted) context.read<AppointmentProvider>().load();
      await _load();
      _toast('Đã đổi lịch (chờ bác sĩ xác nhận lại)');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _cancel(Appointment a) async {
    final reason = await promptReason(context,
        title: 'Hủy lịch #${a.id}', hint: 'Lý do hủy', confirmLabel: 'Hủy lịch');
    if (reason == null) return;
    try {
      await _service.cancelAppointment(a.id, reason);
      if (mounted) context.read<AppointmentProvider>().load();
      await _load();
      _toast('Đã hủy lịch');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  void _rebook(Appointment a) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateAppointmentScreen(preselectDoctorId: a.doctorId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lịch khám #${widget.appointmentId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Lỗi: $_error'))
              : _content(_appt!),
    );
  }

  Widget _content(Appointment a) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row('Thời gian', _fmt(a.apTime)),
        _row('Bác sĩ', a.doctorName),
        _row('Địa chỉ', a.address),
        _row('Trạng thái', a.statusLabel),
        const Divider(height: 24),
        _row('Ghi chú của bạn', (a.note == null || a.note!.isEmpty) ? '—' : a.note!),
        _row('Ghi chú bác sĩ', (a.doctorNote == null || a.doctorNote!.isEmpty) ? '—' : a.doctorNote!),
        if (a.isCanceled) ...[
          const Divider(height: 24),
          _row('Lý do hủy', a.cancelReason ?? '',
              valueColor: Colors.red),
          _row('Người hủy', a.canceledByDoctor ? 'Bác sĩ' : 'Bạn'),
        ],
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (!a.isCanceled && !a.isExamined)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.smart_toy),
              label: const Text('Gửi AI'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AiReportScreen(appointment: a)),
              ),
            ),
          if (a.canReschedule)
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Đổi lịch'),
              onPressed: () => _reschedule(a),
            ),
          if (!a.isCanceled && !a.isExamined)
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text('Hủy lịch', style: TextStyle(color: Colors.red)),
              onPressed: () => _cancel(a),
            ),
          if (a.isCanceled && a.canceledByDoctor && a.doctorId != null)
            FilledButton.icon(
              icon: const Icon(Icons.event_available),
              label: const Text('Đặt lại với bác sĩ này'),
              onPressed: () => _rebook(a),
            ),
        ]),
        if (a.rescheduled && !a.isCanceled)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Đã dùng 1 lần đổi lịch — chỉ có thể hủy.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _row(String k, String v, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text(v, style: TextStyle(color: valueColor))),
          ],
        ),
      );
}
