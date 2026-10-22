import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/billing_ui.dart';
import '../core/dio_client.dart';
import '../core/payment_success.dart';
import '../core/ui.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../services/payment_service.dart';

/// Patient pays an examined appointment: bill → cash or VietQR → waits for confirmation.
class PaymentScreen extends StatefulWidget {
  final Appointment appointment;
  const PaymentScreen({super.key, required this.appointment});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _payments = PaymentService();
  final _appointments = AppointmentService();
  late Appointment _a = widget.appointment;
  late String? _method = widget.appointment.paymentMethod; // chosen radio
  QrInfo? _qr;
  bool _submitting = false;
  bool _done = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    if (_a.isPaymentPending) {
      if (_method == 'qr') _submit(); // re-show the QR
      _startPolling();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Ask the server every 3s; SePay webhook (QR) or admin (cash) flips it to paid.
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final a = await _appointments.getAppointment(_a.id);
        if (!mounted) return;
        setState(() => _a = a);
        if (a.isPaid) {
          _poll?.cancel();
          setState(() => _done = true);
        }
      } catch (_) {
        // transient network error: keep polling
      }
    });
  }

  Future<void> _submit() async {
    final method = _method;
    if (method == null) return;
    setState(() => _submitting = true);
    try {
      final qr = await _payments.pay(_a.id, method);
      setState(() => _qr = qr);
      _startPolling();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(DioClient.messageFrom(e))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _qrPanel(QrInfo qr) {
    final t = Theme.of(context).textTheme;
    Widget info(String label, String value, {bool copy = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            SizedBox(width: 110, child: Text(label, style: t.bodySmall)),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (copy)
              IconButton(
                tooltip: 'Sao chép',
                iconSize: 18,
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép')));
                },
              ),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('Quét mã bằng app ngân hàng', style: t.titleMedium),
          const SizedBox(height: 12),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: QrImageView(
              data: qr.payload,
              version: QrVersions.auto,
              size: 240,
              backgroundColor: Colors.white,
              semanticsLabel: 'Mã VietQR thanh toán',
            ),
          ),
          const SizedBox(height: 12),
          info('Ngân hàng', qr.bankName),
          info('Số tài khoản', qr.accountNo, copy: true),
          info('Người nhận', qr.accountName),
          info('Số tiền', fmtMoney(qr.amount)),
          info('Nội dung CK', qr.content, copy: true),
          const SizedBox(height: 8),
          _waiting('Đang chờ nhân viên xác nhận đã nhận tiền… Màn hình sẽ tự cập nhật.'),
        ]),
      ),
    );
  }

  Widget _waiting(String text) => Row(children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ]);

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return PaymentSuccess(
        amount: _a.payable ?? 0,
        method: _a.paymentMethod ?? _method ?? 'qr',
        onDone: () => Navigator.of(context).pop(true),
      );
    }
    final pendingCash = _a.isPaymentPending && _a.paymentMethod == 'cash' && _qr == null;
    return Scaffold(
      appBar: AppBar(title: Text('Thanh toán lịch #${_a.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BillCard(_a),
          const SizedBox(height: 12),
          Text('Phương thức thanh toán', style: Theme.of(context).textTheme.titleMedium),
          RadioGroup<String>(
            groupValue: _method,
            onChanged: (v) => setState(() => _method = v),
            child: const Column(children: [
              RadioListTile(
                value: 'cash',
                title: Text('Tiền mặt'),
                subtitle: Text('Thanh toán tại quầy'),
                secondary: Icon(Icons.payments_outlined),
              ),
              RadioListTile(
                value: 'qr',
                title: Text('Chuyển khoản QR'),
                subtitle: Text('Quét VietQR bằng app ngân hàng'),
                secondary: Icon(Icons.qr_code_2),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _method == null || _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_a.isPaymentPending ? 'Cập nhật phương thức' : 'Xác nhận thanh toán'),
          ),
          const SizedBox(height: 16),
          if (_qr != null) _qrPanel(_qr!),
          if (pendingCash || (_qr == null && _a.isPaymentPending && _method == 'cash'))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Vui lòng thanh toán ${fmtMoney(_a.payable ?? 0)} tại quầy, đọc mã lịch #${_a.id}.',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  _waiting('Đang chờ nhân viên xác nhận đã nhận tiền…'),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
