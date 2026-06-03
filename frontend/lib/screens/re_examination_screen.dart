import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../providers/doctor_provider.dart';

class ReExaminationScreen extends StatefulWidget {
  final int patientId;
  final String patientName;
  final String defaultAddress;

  const ReExaminationScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.defaultAddress,
  });

  @override
  State<ReExaminationScreen> createState() => _ReExaminationScreenState();
}

class _ReExaminationScreenState extends State<ReExaminationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _address =
      TextEditingController(text: widget.defaultAddress);
  final _note = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _submitting = false;

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime get _apTime =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<DoctorProvider>();
    setState(() => _submitting = true);
    try {
      await provider.reExamination(
        patientId: widget.patientId,
        apTime: _apTime.toUtc().toIso8601String(),
        address: _address.text.trim(),
        note: _note.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo lịch tái khám')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(DioClient.messageFrom(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tái khám')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bệnh nhân: ${widget.patientName}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text('${_date.day}/${_date.month}/${_date.year}'),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (p != null) setState(() => _date = p);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(_time.format(context)),
                      onPressed: () async {
                        final p = await showTimePicker(context: context, initialTime: _time);
                        if (p != null) setState(() => _time = p);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Địa chỉ khám', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập địa chỉ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Tạo lịch tái khám'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
