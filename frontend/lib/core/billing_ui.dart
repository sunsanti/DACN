import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/disease.dart';
import '../services/disease_service.dart';
import 'dio_client.dart';
import 'ui.dart';

String pct(double r) => '${(r * 100).round()}%';

/// Small "BHYT" label for lines reimbursed by insurance.
class BhytTag extends StatelessWidget {
  const BhytTag({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Colors.teal.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('BHYT', style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

/// Payment state pill: Chưa thanh toán / Chờ xác nhận (Tiền mặt|QR) / Đã thanh toán.
class PaymentChip extends StatelessWidget {
  final Appointment a;
  const PaymentChip(this.a, {super.key});

  @override
  Widget build(BuildContext context) {
    final method = a.paymentMethod == 'qr' ? 'QR' : 'Tiền mặt';
    final (label, color) = a.isPaid
        ? ('Đã thanh toán', Colors.green.shade700)
        : a.isPaymentPending
            ? ('Chờ xác nhận · $method', Colors.orange.shade800)
            : ('Chưa thanh toán', Colors.red.shade700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Bill from an appointment's snapshot: each line (BHYT tag), total, BHYT share, amount to pay.
class BillCard extends StatelessWidget {
  final Appointment a;
  final bool showPayment; // payment status pill in the header
  const BillCard(this.a, {super.key, this.showPayment = true});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    Widget line(String label, String value, {TextStyle? style, bool bhyt = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(
              child: Row(children: [
                Flexible(child: Text(label, style: style)),
                if (bhyt) ...[const SizedBox(width: 6), const BhytTag()],
              ]),
            ),
            const SizedBox(width: 8),
            Text(value, style: style),
          ]),
        );
    final rate = a.insuranceRate ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.receipt_long, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Chi phí khám', style: t.titleMedium)),
              if (showPayment) PaymentChip(a),
            ]),
            const SizedBox(height: 8),
            line('Phí khám', fmtMoney(a.examFee ?? 0), bhyt: a.examFeeCovered),
            for (final i in a.items) line(i.name, fmtMoney(i.price), bhyt: i.bhytCovered),
            const Divider(),
            line('Tổng', fmtMoney(a.total ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
            if (rate > 0)
              line('BHYT chi trả (${pct(rate)} × ${fmtMoney(a.coveredBase)})', fmtMoney(-(a.insuranceCovered ?? 0)),
                  style: TextStyle(color: Colors.green.shade700))
            else
              line('BHYT', 'Không áp dụng', style: TextStyle(color: cs.onSurfaceVariant)),
            const Divider(),
            line('Cần thanh toán', fmtMoney(a.payable ?? 0),
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary)),
          ],
        ),
      ),
    );
  }
}

/// Doctor picks ≥1 disease/service before completing a visit. Returns the ids, or null if cancelled.
Future<List<int>?> pickDiseases(BuildContext context) async {
  final PriceList list;
  try {
    list = await DiseaseService().list();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(DioClient.messageFrom(e))));
    }
    return null;
  }
  if (!context.mounted) return null;
  return showDialog<List<int>>(context: context, builder: (_) => _DiseasePicker(list));
}

class _DiseasePicker extends StatefulWidget {
  final PriceList list;
  const _DiseasePicker(this.list);

  @override
  State<_DiseasePicker> createState() => _DiseasePickerState();
}

class _DiseasePickerState extends State<_DiseasePicker> {
  final _selected = <int>{};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.list.items
        .where((d) => d.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    final subtotal = widget.list.examFee +
        widget.list.items.where((d) => _selected.contains(d.id)).fold<int>(0, (s, d) => s + d.price);
    return AlertDialog(
      title: const Text('Chọn bệnh / dịch vụ'),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên'),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.list.items.isEmpty
                ? const Center(child: Text('Admin chưa lập bảng giá.'))
                : ListView(children: [
                    for (final d in items)
                      CheckboxListTile(
                        dense: true,
                        value: _selected.contains(d.id),
                        title: Row(children: [
                          Flexible(child: Text(d.name)),
                          if (d.bhytCovered) ...[const SizedBox(width: 6), const BhytTag()],
                        ]),
                        subtitle: Text(fmtMoney(d.price)),
                        onChanged: (v) => setState(() => v! ? _selected.add(d.id) : _selected.remove(d.id)),
                      ),
                  ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Expanded(
                child: Text('Tạm tính (phí khám ${fmtMoney(widget.list.examFee)} + ${_selected.length} mục), chưa trừ BHYT',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              Text(fmtMoney(subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
        FilledButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected.toList()),
          child: const Text('Hoàn thành khám'),
        ),
      ],
    );
  }
}

/// Colored pill for the card status (valid / expired / ...).
class InsuranceBadge extends StatelessWidget {
  final String status;
  const InsuranceBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'valid' => ('Còn hạn', Colors.green.shade700),
      'expired' => ('Hết hạn', Colors.red.shade700),
      'not_yet_valid' => ('Chưa đến hạn', Colors.orange.shade800),
      _ => ('Chưa khai', Colors.grey.shade700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
