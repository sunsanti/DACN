import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../core/billing_ui.dart';
import '../core/ui.dart';
import '../models/disease.dart';
import '../providers/admin_provider.dart';

/// Admin: price list per disease/service. No delete — switch off instead (old bills keep their snapshot).
class AdminDiseaseScreen extends StatefulWidget {
  const AdminDiseaseScreen({super.key});

  @override
  State<AdminDiseaseScreen> createState() => _AdminDiseaseScreenState();
}

class _AdminDiseaseScreenState extends State<AdminDiseaseScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      await context.read<AdminProvider>().loadPrices();
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = DioClient.messageFrom(e));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(DioClient.messageFrom(e))));
    }
  }

  /// Add (d == null) or edit name/price.
  Future<void> _edit([Disease? d]) async {
    final name = TextEditingController(text: d?.name ?? '');
    final price = TextEditingController(text: d?.price.toString() ?? '');
    var bhyt = d?.bhytCovered ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
        title: Text(d == null ? 'Thêm bệnh / dịch vụ' : 'Sửa giá'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên bệnh / dịch vụ')),
          const SizedBox(height: 12),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Giá (VND)', suffixText: 'đ'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('BHYT chi trả'),
            value: bhyt,
            onChanged: (v) => setLocal(() => bhyt = v),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      )),
    );
    final n = name.text.trim();
    final p = int.tryParse(price.text);
    name.dispose();
    price.dispose();
    if (ok != true || !mounted) return;
    if (n.isEmpty || p == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nhập tên và giá hợp lệ')));
      return;
    }
    final provider = context.read<AdminProvider>();
    await _run(() => d == null
        ? provider.addDisease(n, p, bhytCovered: bhyt)
        : provider.updateDisease(d.id, name: n, price: p, bhytCovered: bhyt));
  }

  @override
  Widget build(BuildContext context) {
    final prices = context.watch<AdminProvider>().prices;
    final items = prices?.items ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Bảng giá bệnh')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? EmptyState(Icons.cloud_off, 'Lỗi tải dữ liệu:\n$_error')
            : prices == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_hospital_outlined),
                          title: const Text('Phí khám cố định (mọi lượt khám)'),
                          subtitle: Text(prices.examFeeBhytCovered
                              ? 'BHYT chi trả · cấu hình qua env EXAM_FEE'
                              : 'BHYT không chi trả · cấu hình qua env EXAM_FEE'),
                          trailing: Text(fmtMoney(prices.examFee),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Chưa có bệnh nào. Nhấn "Thêm".', textAlign: TextAlign.center),
                        ),
                      for (final d in items)
                        Card(
                          child: ListTile(
                            onTap: () => _edit(d),
                            title: Text(d.name,
                                style: TextStyle(
                                    decoration: d.active ? null : TextDecoration.lineThrough,
                                    color: d.active ? null : Theme.of(context).colorScheme.outline)),
                            subtitle: Row(children: [
                              Text(d.active ? fmtMoney(d.price) : '${fmtMoney(d.price)} · đã tắt'),
                              const SizedBox(width: 8),
                              if (d.bhytCovered)
                                const BhytTag()
                              else
                                Text('Không BHYT', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
                            ]),
                            trailing: Switch(
                              value: d.active,
                              onChanged: (v) => _run(
                                  () => context.read<AdminProvider>().updateDisease(d.id, active: v)),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
