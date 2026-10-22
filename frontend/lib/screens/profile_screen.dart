import 'package:flutter/material.dart';

import '../core/billing_ui.dart';
import '../core/dio_client.dart';
import '../core/ui.dart';
import '../models/patient.dart';
import '../services/appointment_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = AppointmentService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _gender = 'male';
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Patient? _patient; // for the read-only CCCD / BHYT section

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _age, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await _service.getMe();
      _name.text = p.name;
      _age.text = p.age.toString();
      _phone.text = p.phone;
      _address.text = p.address;
      _gender = (p.gender == 'female') ? 'female' : 'male';
      _patient = p;
    } catch (e) {
      _error = DioClient.messageFrom(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ]),
      );

  /// CCCD (read-only) + "Mã BHYT" — the BHYT block only exists when the registry has a card for this CCCD.
  Widget _identityCard() {
    final p = _patient!;
    final ins = p.insurance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.badge_outlined),
            const SizedBox(width: 8),
            Text('Định danh & BHYT', style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: 8),
          _row('Số CCCD', p.cccd ?? 'Chưa có'),
          if (ins != null) ...[
            const Divider(height: 20),
            Row(children: [
              const Icon(Icons.health_and_safety_outlined, size: 20),
              const SizedBox(width: 6),
              const Expanded(child: Text('Mã BHYT', style: TextStyle(fontWeight: FontWeight.w700))),
              InsuranceBadge(ins.status),
            ]),
            const SizedBox(height: 6),
            SelectableText(ins.cardNumber,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            _row('Mức hưởng', pct(ins.rate)),
            _row('Hiệu lực', '${fmtDate(DateTime.parse(ins.validFrom))} – ${fmtDate(DateTime.parse(ins.validTo))}'),
          ],
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.updateMe({
        'name': _name.text.trim(),
        'gender': _gender,
        'age': int.tryParse(_age.text) ?? 0,
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật hồ sơ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(DioClient.messageFrom(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? kb, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: kb,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ của tôi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Lỗi: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _field(_name, 'Họ tên',
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _field(_age, 'Tuổi', kb: TextInputType.number,
                                  validator: (v) => int.tryParse(v ?? '') == null ? 'Số' : null),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _gender,
                                decoration: const InputDecoration(labelText: 'Giới tính'),
                                items: const [
                                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                                ],
                                onChanged: (v) => setState(() => _gender = v ?? 'male'),
                              ),
                            ),
                          ],
                        ),
                        _field(_phone, 'Số điện thoại', kb: TextInputType.phone),
                        _field(_address, 'Địa chỉ'),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Lưu thay đổi'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _identityCard(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
