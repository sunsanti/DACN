import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../models/doctor.dart';
import '../providers/appointment_provider.dart';
import '../services/appointment_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final int? preselectDoctorId;
  const CreateAppointmentScreen({super.key, this.preselectDoctorId});

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

  List<DateTime> _slots = [];
  DateTime? _selectedSlot;
  bool _loadingSlots = false;
  String? _slotError;

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

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _loadDoctors() async {
    try {
      final docs = await _service.listDoctors();
      Doctor? initial = docs.isNotEmpty ? docs.first : null;
      if (widget.preselectDoctorId != null) {
        for (final d in docs) {
          if (d.id == widget.preselectDoctorId) {
            initial = d;
            break;
          }
        }
      }
      setState(() {
        _doctors = docs;
        _selectedDoctor = initial;
        _loadingDoctors = false;
      });
      _loadSlots();
    } catch (e) {
      setState(() {
        _loadError = DioClient.messageFrom(e);
        _loadingDoctors = false;
      });
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedDoctor == null) return;
    setState(() {
      _loadingSlots = true;
      _slots = [];
      _selectedSlot = null;
      _slotError = null;
    });
    try {
      final slots = await _service.availability(_selectedDoctor!.id, _dateStr);
      setState(() => _slots = slots);
    } catch (e) {
      setState(() => _slotError = DioClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctor == null) {
      _toast('Chưa có bác sĩ để chọn');
      return;
    }
    if (_selectedSlot == null) {
      _toast('Hãy chọn một khung giờ trống');
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<AppointmentProvider>().create(
            apTime: _selectedSlot!,
            address: _address.text.trim(),
            doctorId: _selectedDoctor!.id,
            note: _note.text.trim(),
          );
      if (mounted) {
        _toast('Đặt lịch thành công');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
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
                      onChanged: (d) {
                        setState(() => _selectedDoctor = d);
                        _loadSlots();
                      },
                      validator: (d) => d == null ? 'Chọn bác sĩ' : null,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text('Ngày: ${_date.day}/${_date.month}/${_date.year}'),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (p != null) {
                          setState(() => _date = p);
                          _loadSlots();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Khung giờ trống (theo ca trực của bác sĩ):',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _slotsView(),
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

  Widget _slotsView() {
    if (_loadingSlots) {
      return const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator());
    }
    if (_slotError != null) {
      return Text('Lỗi: $_slotError', style: const TextStyle(color: Colors.red));
    }
    if (_slots.isEmpty) {
      return const Text(
        'Bác sĩ chưa đăng ký ca trực ngày này (hoặc đã kín). '
        'Hãy chọn ngày khác hoặc bác sĩ khác.',
        style: TextStyle(color: Colors.grey),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _slots.map((s) {
        final sel = _selectedSlot == s;
        return ChoiceChip(
          label: Text(_hm(s)),
          selected: sel,
          onSelected: (_) => setState(() => _selectedSlot = s),
        );
      }).toList(),
    );
  }
}
