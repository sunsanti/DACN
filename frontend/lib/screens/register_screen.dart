import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController(text: '20');
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _gender = 'male';
  DateTime _birthDate = DateTime(2000, 1, 1);
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
    setState(() => _submitting = true);
    try {
      await context.read<AuthProvider>().register(
            email: _email.text.trim(),
            password: _password.text,
            name: _name.text.trim(),
            gender: _gender,
            age: int.tryParse(_age.text) ?? 0,
            birthDate: _birthDate.toIso8601String().split('T').first,
            phone: _phone.text.trim(),
            address: _address.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(); // AuthGate handles the rest
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
      appBar: AppBar(title: const Text('Đăng ký bệnh nhân')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_email, 'Email', keyboard: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null),
              _field(_password, 'Mật khẩu (≥ 6 ký tự)', obscure: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null),
              _field(_name, 'Họ tên', validator: _required),
              Row(
                children: [
                  Expanded(
                    child: _field(_age, 'Tuổi', keyboard: TextInputType.number,
                        validator: (v) => (int.tryParse(v ?? '') == null) ? 'Số' : null),
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
                title: Text('Ngày sinh: ${_birthDate.toIso8601String().split('T').first}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate,
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _birthDate = picked);
                },
              ),
              _field(_phone, 'Số điện thoại', keyboard: TextInputType.phone, validator: _required),
              _field(_address, 'Địa chỉ', validator: _required),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Đăng ký'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null;

  Widget _field(
    TextEditingController c,
    String label, {
    bool obscure = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validator,
      ),
    );
  }
}
