import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../providers/admin_provider.dart';
import '../services/admin_service.dart';

class AdminDoctorDetailScreen extends StatefulWidget {
  final int doctorId;
  const AdminDoctorDetailScreen({super.key, required this.doctorId});

  @override
  State<AdminDoctorDetailScreen> createState() => _AdminDoctorDetailScreenState();
}

class _AdminDoctorDetailScreenState extends State<AdminDoctorDetailScreen> {
  final _service = AdminService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
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
    for (final c in [_name, _age, _phone, _address, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await _service.getDoctor(widget.doctorId);
      _name.text = d.name;
      _age.text = d.age.toString();
      _phone.text = d.phone;
      _address.text = d.address;
      _email.text = d.email;
      _gender = d.gender == 'female' ? 'female' : 'male';
    } catch (e) {
      _error = DioClient.messageFrom(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminProvider>();
    setState(() => _saving = true);
    try {
      await _service.updateDoctor(widget.doctorId, {
        'name': _name.text.trim(),
        'age': int.tryParse(_age.text) ?? 0,
        'gender': _gender,
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'email': _email.text.trim(),
      });
      await provider.load(); // refresh the salary list (names may change)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật bác sĩ')),
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
      appBar: AppBar(title: Text('Bác sĩ #${widget.doctorId}')),
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
                        _field(_email, 'Email', kb: TextInputType.emailAddress),
                        _field(_phone, 'Số điện thoại', kb: TextInputType.phone),
                        _field(_address, 'Địa chỉ phòng khám'),
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
