import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../providers/admin_provider.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController(text: '35');
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _gender = 'male';
  DateTime _dob = DateTime(1990, 1, 1);
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_email, _password, _name, _age, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminProvider>();
    setState(() => _submitting = true);
    try {
      await provider.addDoctor(
        email: _email.text.trim(),
        password: _password.text,
        name: _name.text.trim(),
        age: int.tryParse(_age.text) ?? 0,
        dateOfBirth: _dob.toIso8601String().split('T').first,
        gender: _gender,
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm bác sĩ')),
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

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null;

  Widget _field(TextEditingController c, String label,
      {bool obscure = false, TextInputType? kb, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: kb,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm bác sĩ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_email, 'Email', kb: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null),
              _field(_password, 'Mật khẩu (≥ 6 ký tự)', obscure: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null),
              _field(_name, 'Họ tên bác sĩ', validator: _req),
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
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                title: Text('Ngày sinh: ${_dob.toIso8601String().split('T').first}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _dob,
                    firstDate: DateTime(1940),
                    lastDate: DateTime.now(),
                  );
                  if (p != null) setState(() => _dob = p);
                },
              ),
              const SizedBox(height: 12),
              _field(_phone, 'Số điện thoại', kb: TextInputType.phone, validator: _req),
              _field(_address, 'Địa chỉ phòng khám', validator: _req),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Tạo tài khoản bác sĩ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
