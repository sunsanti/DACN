import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../models/appointment.dart';
import '../providers/doctor_provider.dart';
import '../services/doctor_service.dart';
import 're_examination_screen.dart';

class DoctorAppointmentDetailScreen extends StatefulWidget {
  final int appointmentId;
  const DoctorAppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<DoctorAppointmentDetailScreen> createState() => _State();
}

class _State extends State<DoctorAppointmentDetailScreen> {
  final _service = DoctorService();
  Appointment? _a;
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
      _a = await _service.getDetail(widget.appointmentId);
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

  Future<void> _complete() async {
    final provider = context.read<DoctorProvider>();
    try {
      await provider.complete(widget.appointmentId);
      _toast('Đã đánh dấu khám xong');
      await _load();
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lịch hẹn #${widget.appointmentId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Lỗi: $_error'))
              : _content(_a!),
    );
  }

  Widget _content(Appointment a) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Thông tin lịch hẹn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        _row('Thời gian', _fmt(a.apTime)),
        _row('Địa chỉ', a.address),
        _row('Ghi chú', (a.note == null || a.note!.isEmpty) ? '—' : a.note!),
        _row('Trạng thái', a.statusLabel),
        const Divider(height: 28),
        const Text('Thông tin bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        _row('Họ tên', a.patientName),
        _row('Tuổi', a.patientAge.toString()),
        _row('SĐT', a.patientPhone.isEmpty ? '—' : a.patientPhone),
        _row('Địa chỉ', a.patientAddress.isEmpty ? '—' : a.patientAddress),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (a.isConfirmed)
            FilledButton.icon(
              icon: const Icon(Icons.task_alt),
              label: const Text('Đã khám xong'),
              onPressed: _complete,
            ),
          if (a.isExamined && a.patientId != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.event_repeat),
              label: const Text('Tái khám'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReExaminationScreen(
                    patientId: a.patientId!,
                    patientName: a.patientName,
                    defaultAddress: a.address,
                  ),
                ),
              ),
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
