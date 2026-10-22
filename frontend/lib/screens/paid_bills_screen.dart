import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ui.dart';
import '../providers/appointment_provider.dart';
import 'appointment_detail_screen.dart';

/// Paid bills, newest payment first. Filtered client-side from the patient's appointments.
class PaidBillsScreen extends StatelessWidget {
  const PaidBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final paid = provider.appointments.where((a) => a.isPaid && a.hasBill).toList()
      ..sort((x, y) => (y.paidAt ?? y.apTime).compareTo(x.paidAt ?? x.apTime));
    final total = paid.fold<int>(0, (s, a) => s + a.payable!);
    final green = Colors.green.shade700;

    return Scaffold(
      appBar: AppBar(title: const Text('Hoá đơn đã trả')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppointmentProvider>().load(),
        child: paid.isEmpty
            ? const EmptyState(Icons.receipt_long_outlined, 'Chưa có hoá đơn nào đã thanh toán.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text('${paid.length} hoá đơn  ·  tổng đã trả ${fmtMoney(total)}',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  for (final a in paid)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                        leading: CircleAvatar(
                          backgroundColor: green.withValues(alpha: 0.12),
                          child: Icon(Icons.receipt_long, color: green),
                        ),
                        title: Text('BS. ${a.doctorName}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'Khám ${fmtDate(a.apTime)}'
                          '${a.paidAt != null ? '  ·  trả ${fmtDate(a.paidAt!)}' : ''}'
                          '  ·  ${a.paymentMethod == 'qr' ? 'QR' : 'Tiền mặt'}',
                        ),
                        trailing: Text(fmtMoney(a.payable!),
                            style: TextStyle(fontWeight: FontWeight.w700, color: green)),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => AppointmentDetailScreen(appointmentId: a.id)),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
