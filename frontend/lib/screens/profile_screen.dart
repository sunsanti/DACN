import 'package:flutter/material.dart';

import '../core/dio_client.dart';
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
    } catch (e) {
      _error = DioClient.messageFrom(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
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
                          children: [
                            Expanded(
                              child: _field(_age, 'Tuổi', kb: TextInputType.number,
                                  validator: (v) => int.tryParse(v ?? '') == null ? 'Số' : null),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _gender,
                                decoration: const InputDecoration(labelText: 'Giới tính', border: OutlineInputBorder()),
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
                      ],
                    ),
                  ),
                ),
    );
  }
}
