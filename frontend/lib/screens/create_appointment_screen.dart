import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../models/doctor.dart';
import '../providers/appointment_provider.dart';
import '../services/appointment_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  const CreateAppointmentScreen({super.key});

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _note = TextEditingController();
  final _service = AppointmentService();

  List<Doctor> _doctors = [];
  Doctor? _selectedDoctor;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _loadingDoctors = true;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    try {
      final docs = await _service.listDoctors();
      setState(() {
        _doctors = docs;
        _selectedDoctor = docs.isNotEmpty ? docs.first : null;
        _loadingDoctors = false;
      });
    } catch (e) {
      setState(() {
        _loadError = DioClient.messageFrom(e);
        _loadingDoctors = false;
      });
    }
  }

  DateTime get _apTime =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có bác sĩ để chọn')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<AppointmentProvider>().create(
            apTime: _apTime,
            address: _address.text.trim(),
            doctorId: _selectedDoctor!.id,
            note: _note.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt lịch thành công')),
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
      appBar: AppBar(title: const Text('Đặt lịch khám')),
      body: _loadingDoctors
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_loadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('Không tải được danh sách bác sĩ: $_loadError',
                            style: const TextStyle(color: Colors.red)),
                      ),
                    DropdownButtonFormField<Doctor>(
                      initialValue: _selectedDoctor,
                      decoration: const InputDecoration(labelText: 'Bác sĩ', border: OutlineInputBorder()),
                      items: _doctors
                          .map((d) => DropdownMenuItem(value: d, child: Text('BS. ${d.name} (#${d.id})')))
                          .toList(),
                      onChanged: (d) => setState(() => _selectedDoctor = d),
                      validator: (d) => d == null ? 'Chọn bác sĩ' : null,
                    ),
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
                      decoration: const InputDecoration(
                          labelText: 'Ghi chú / triệu chứng (tuỳ chọn)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Xác nhận đặt lịch'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
