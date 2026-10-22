import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import '../core/dio_client.dart';
import '../core/ui.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

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
  XFile? _avatar; // tuỳ chọn
  final _cccd = TextEditingController(); // bắt buộc, 12 số

  // BHYT preview: chỉ tra khi đủ 12 số CCCD và người dùng đã tự chọn ngày sinh.
  bool _birthPicked = false;
  Timer? _debounce;
  int _lookupSeq = 0; // bỏ kết quả của request cũ
  bool _bhytLoading = false;
  Map<String, dynamic>? _bhyt; // null = chưa tra
  bool _bhytError = false;

  @override
  void initState() {
    super.initState();
    _cccd.addListener(_scheduleLookup);
  }

  void _scheduleLookup() {
    _debounce?.cancel();
    final seq = ++_lookupSeq;
    if (!RegExp(r'^\d{12}$').hasMatch(_cccd.text) || !_birthPicked) {
      if (_bhyt != null || _bhytLoading || _bhytError) {
        setState(() {
          _bhyt = null;
          _bhytLoading = false;
          _bhytError = false;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() {
        _bhytLoading = true;
        _bhytError = false;
      });
      try {
        final r = await AuthService().bhytLookup(_cccd.text, _birthDate.toIso8601String().split('T').first);
        if (!mounted || seq != _lookupSeq) return;
        setState(() => _bhyt = r);
      } catch (_) {
        if (!mounted || seq != _lookupSeq) return;
        setState(() {
          _bhyt = null;
          _bhytError = true;
        });
      } finally {
        if (mounted && seq == _lookupSeq) setState(() => _bhytLoading = false);
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_email, _password, _name, _age, _phone, _address]) {
      c.dispose();
    }
    _debounce?.cancel();
    _cccd.dispose();
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
            avatar: _avatar,
            cccd: _cccd.text.trim(),
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
              AvatarPicker(onChanged: (f) => _avatar = f),
              const SizedBox(height: 16),
              _field(_email, 'Email', keyboard: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null),
              _field(_password, 'Mật khẩu (≥ 6 ký tự)', obscure: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null),
              _field(_name, 'Họ tên', validator: _required),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _cccd,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Số CCCD',
                    helperText: 'Dùng để tra thẻ BHYT. Không sửa được sau khi đăng ký',
                  ),
                  validator: (v) => RegExp(r'^\d{12}$').hasMatch(v ?? '') ? null : 'CCCD gồm đúng 12 chữ số',
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(_age, 'Tuổi', keyboard: TextInputType.number,
                        validator: (v) => (int.tryParse(v ?? '') == null) ? 'Số' : null),
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
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate,
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _birthDate = picked;
                      _birthPicked = true;
                    });
                    _scheduleLookup();
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày sinh',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(fmtDate(_birthDate)),
                ),
              ),
              const SizedBox(height: 12),
              _bhytField(),
              const SizedBox(height: 12),
              _field(_phone, 'Số điện thoại', keyboard: TextInputType.phone, validator: _required),
              _field(_address, 'Địa chỉ', validator: _required),
              const SizedBox(height: 4),
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

  /// Ô "Thẻ BHYT" chỉ đọc, nền xám: kết quả tra theo CCCD + ngày sinh.
  Widget _bhytField() {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    Widget content;
    if (_bhytError) {
      content = Text('Không tra được, thử lại sau', style: muted);
    } else if (_bhyt == null) {
      content = Text('Nhập CCCD và ngày sinh để tra', style: muted);
    } else if (_bhyt!['found'] != true) {
      content = Text('Không tìm thấy thẻ BHYT', style: muted);
    } else {
      final rate = ((_bhyt!['rate'] as num) * 100).round();
      final validTo = DateTime.parse(_bhyt!['validTo'] as String);
      content = Text.rich(TextSpan(children: [
        TextSpan(text: '${_bhyt!['cardNumber']} · $rate% · HSD ${fmtDate(validTo)}'),
        if (_bhyt!['status'] == 'expired')
          TextSpan(text: '  đã hết hạn', style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
        if (_bhyt!['status'] == 'not_yet_valid')
          TextSpan(text: '  chưa có hiệu lực', style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
      ]));
    }
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Thẻ BHYT',
        enabled: false,
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        helperText: 'Tự tra theo CCCD và ngày sinh, không sửa được',
        suffixIcon: _bhytLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : Icon(Icons.health_and_safety_outlined, color: scheme.onSurfaceVariant),
      ),
      child: content,
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
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }
}
