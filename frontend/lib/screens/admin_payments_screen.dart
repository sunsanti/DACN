import 'dart:async';

import 'package:flutter/material.dart';

import '../core/billing_ui.dart';
import '../core/dio_client.dart';
import '../core/ui.dart';
import '../models/appointment.dart';
import '../services/payment_service.dart';

/// Admin: bills waiting for confirmation (cash at the counter, or transfers to check) and paid ones.
class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A tab of AdminHomeScreen: no own AppBar. The TabBar theme is styled for the primary
    // AppBar, so sit it on a primary strip that continues the AppBar.
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        Material(
          color: Theme.of(context).colorScheme.primary,
          child: const TabBar(tabs: [Tab(text: 'Chờ xác nhận'), Tab(text: 'Đã thanh toán')]),
        ),
        const Expanded(
          child: TabBarView(children: [_PaymentList('pending'), _PaymentList('paid')]),
        ),
      ]),
    );
  }
}

class _PaymentList extends StatefulWidget {
  final String status;
  const _PaymentList(this.status);

  @override
  State<_PaymentList> createState() => _PaymentListState();
}

class _PaymentListState extends State<_PaymentList> {
  final _service = PaymentService();
  List<Appointment>? _items;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    // Patients pick / change cash↔QR at any time: keep the list (method, new bills) current.
    // ponytail: 5 s polling, push (websocket) if it ever needs to be instant at scale.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _service.payments(widget.status);
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      // keep showing the last good list if a background refresh fails
      if (mounted && _items == null) setState(() => _error = DioClient.messageFrom(e));
    }
  }

  Future<void> _confirm(Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã nhận tiền?'),
        content: Text('${fmtMoney(a.payable ?? 0)} · ${a.patientName} · lịch #${a.id}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đã nhận tiền')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.confirm(a.id);
      messenger.showSnackBar(SnackBar(content: Text('Đã xác nhận lịch #${a.id}')));
      _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(DioClient.messageFrom(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return RefreshIndicator(
      onRefresh: _load,
      child: _error != null
          ? EmptyState(Icons.cloud_off, 'Lỗi tải dữ liệu:\n$_error')
          : items == null
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? EmptyState(Icons.receipt_long,
                      widget.status == 'pending' ? 'Không có khoản nào chờ xác nhận.' : 'Chưa có khoản đã thanh toán.')
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final a in items)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(fmtMoney(a.payable ?? 0),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                  ),
                                  PaymentChip(a),
                                ]),
                                InfoLine(Icons.person_outline, 'BN ${a.patientName}'),
                                InfoLine(Icons.medical_services_outlined, 'BS. ${a.doctorName} · lịch #${a.id}'),
                                InfoLine(Icons.notes, 'Nội dung CK: DACN${a.id}'),
                                if (a.paidAt != null) InfoLine(Icons.check_circle_outline, 'Lúc ${fmtDateTime(a.paidAt!)}'),
                                if (widget.status == 'pending')
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.tonalIcon(
                                      icon: const Icon(Icons.price_check),
                                      label: const Text('Đã nhận tiền'),
                                      onPressed: () => _confirm(a),
                                    ),
                                  ),
                              ]),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
