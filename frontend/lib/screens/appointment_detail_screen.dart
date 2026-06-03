import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../services/appointment_service.dart';
import 'ai_report_screen.dart';

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

  Future<void> _edit() async {
    final a = _appt!;
    if (a.isConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lịch đã xác nhận — không sửa được')),
      );
      return;
    }
    DateTime date = a.apTime;
    TimeOfDay time = TimeOfDay.fromDateTime(a.apTime);
    final addr = TextEditingController(text: a.address);
    final note = TextEditingController(text: a.note ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Sửa lịch khám'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final p = await showDatePicker(
                            context: ctx, initialDate: date,
                            firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (p != null) setLocal(() => date = p);
                      },
                      child: Text('${date.day}/${date.month}/${date.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final p = await showTimePicker(context: ctx, initialTime: time);
                        if (p != null) setLocal(() => time = p);
                      },
                      child: Text(time.format(ctx)),
                    ),
                  ),
                ]),
                TextField(controller: addr, decoration: const InputDecoration(labelText: 'Địa chỉ')),
                TextField(controller: note, decoration: const InputDecoration(labelText: 'Ghi chú')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final newApTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    try {
      await _service.editAppointment(a.id,
          apTime: newApTime.toUtc().toIso8601String(), address: addr.text.trim(), note: note.text.trim());
      if (mounted) context.read<AppointmentProvider>().load();
      await _load();
      _toast('Đã cập nhật lịch');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá lịch khám?'),
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
      await _service.deleteAppointment(widget.appointmentId);
      if (mounted) {
        context.read<AppointmentProvider>().load();
        Navigator.of(context).pop();
        _toast('Đã xoá lịch');
      }
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
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
        _row('Ghi chú', (a.note == null || a.note!.isEmpty) ? '—' : a.note!),
        _row('Trạng thái', a.statusLabel),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonalIcon(
            icon: const Icon(Icons.smart_toy),
            label: const Text('Gửi AI'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AiReportScreen(appointment: a)),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Sửa'),
            onPressed: _edit,
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Xoá', style: TextStyle(color: Colors.red)),
            onPressed: _delete,
          ),
        ]),
      ],
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(k, style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
