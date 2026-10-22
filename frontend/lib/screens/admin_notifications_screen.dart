import 'package:flutter/material.dart';

import '../core/dio_client.dart';
import '../core/ui.dart';
import '../services/payment_service.dart';

/// Admin inbox: payments received via SePay and transfers that need a manual check.
/// Opening it marks everything as read.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _service = PaymentService();
  List<AdminNotification>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.notifications();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
      await _service.readAll(); // shown → read (unread dots stay visible on this screen)
    } catch (e) {
      if (mounted) setState(() => _error = DioClient.messageFrom(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? EmptyState(Icons.cloud_off, 'Lỗi tải dữ liệu:\n$_error')
            : items == null
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const EmptyState(Icons.notifications_none, 'Chưa có thông báo.')
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          for (final n in items)
                            Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: n.title.startsWith('Đã nhận')
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                                  child: Icon(
                                    n.title.startsWith('Đã nhận') ? Icons.payments : Icons.warning_amber,
                                    color: n.title.startsWith('Đã nhận')
                                        ? Colors.green.shade700
                                        : Colors.orange.shade800,
                                  ),
                                ),
                                title: Row(children: [
                                  Expanded(
                                    child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  if (!n.read)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle),
                                    ),
                                ]),
                                subtitle: Text('${n.body}\n${fmtDateTime(n.createdAt)}'),
                                isThreeLine: true,
                              ),
                            ),
                        ],
                      ),
      ),
    );
  }
}
