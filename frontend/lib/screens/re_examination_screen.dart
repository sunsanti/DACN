import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../core/ui.dart';
import '../providers/doctor_provider.dart';
import '../services/doctor_service.dart';

class ReExaminationScreen extends StatefulWidget {
  final int doctorId;
  final int patientId;
  final String patientName;
  final String defaultAddress;

  const ReExaminationScreen({
    super.key,
    required this.doctorId,
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
  List<DateTime> _slots = [];
  DateTime? _slot;
  bool _loadingSlots = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  /// Only the doctor's own free slots can be picked (backend rejects anything else).
  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _slots = [];
      _slot = null;
    });
    try {
      final d = '${_date.year}-${_date.month}-${_date.day}';
      final slots = await DoctorService().availability(widget.doctorId, d);
      if (mounted) setState(() => _slots = slots);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(DioClient.messageFrom(e))));
      }
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chọn khung giờ')));
      return;
    }
    final provider = context.read<DoctorProvider>();
    setState(() => _submitting = true);
    try {
      await provider.reExamination(
        patientId: widget.patientId,
        apTime: _slot!.toUtc().toIso8601String(),
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
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text('Ngày: ${fmtDate(_date)}'),
                onPressed: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (p != null) {
                    setState(() => _date = p);
                    _loadSlots();
                  }
                },
              ),
              const SizedBox(height: 12),
              if (_loadingSlots)
                const LinearProgressIndicator()
              else if (_slots.isEmpty)
                Text('Bạn chưa đăng ký ca trực ngày này (hoặc đã kín). Hãy chọn ngày khác.',
                    style: TextStyle(color: Theme.of(context).colorScheme.outline))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _slots)
                      ChoiceChip(
                        label: Text(fmtTime(s)),
                        selected: _slot == s,
                        onSelected: (_) => setState(() => _slot = s),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Địa chỉ khám'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập địa chỉ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
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
