import 'package:flutter/material.dart';

import '../core/dio_client.dart';
import '../models/shift.dart';
import '../services/doctor_service.dart';

class DoctorShiftsScreen extends StatefulWidget {
  const DoctorShiftsScreen({super.key});

  @override
  State<DoctorShiftsScreen> createState() => _DoctorShiftsScreenState();
}

class _DoctorShiftsScreenState extends State<DoctorShiftsScreen> {
  final _service = DoctorService();
  List<ShiftAssignment> _shifts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _shifts = await _service.myShifts();
      _error = null;
    } catch (e) {
      _error = DioClient.messageFrom(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _register() async {
    List<ShiftTemplate> templates;
    try {
      templates = await _service.shiftTemplates();
    } catch (e) {
      _toast(DioClient.messageFrom(e));
      return;
    }
    if (!mounted) return;
    final picked = await showDialog<ShiftTemplate>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Chọn ca trực'),
        children: templates
            .map((t) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, t),
                  child: Text('${t.type == 'morning' ? 'Sáng' : 'Chiều'} '
                      '(${t.hours.toStringAsFixed(0)}h)'),
                ))
            .toList(),
      ),
    );
    if (picked == null) return;
    try {
      await _service.registerShift(picked.id);
      _toast('Đã đăng ký ca ${picked.type == 'morning' ? 'sáng' : 'chiều'}');
      await _load();
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _cancel(ShiftAssignment s) async {
    try {
      await _service.cancelAssignment(s.id);
      _toast('Đã huỷ ca #${s.id}');
      await _load();
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _delete(ShiftAssignment s) async {
    try {
      await _service.deleteAssignment(s.id);
      _toast('Đã xoá ca #${s.id}');
      await _load();
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ca trực của tôi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _register,
        icon: const Icon(Icons.add),
        label: const Text('Đăng ký ca'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [const SizedBox(height: 120), Center(child: Text('Lỗi: $_error'))])
                : _shifts.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Chưa có ca trực.\nNhấn "Đăng ký ca".', textAlign: TextAlign.center)),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _shifts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _tile(_shifts[i]),
                      ),
      ),
    );
  }

  Widget _tile(ShiftAssignment s) {
    final canceled = !s.isActive;
    return Card(
      child: ListTile(
        leading: Icon(s.type == 'morning' ? Icons.wb_sunny : Icons.wb_twilight,
            color: canceled ? Colors.grey : Colors.orange),
        title: Text('Ca ${s.type == 'morning' ? 'sáng' : 'chiều'} — ${s.duration.toStringAsFixed(1)}h'),
        subtitle: Text('Trạng thái: ${s.status}',
            style: TextStyle(color: s.isActive ? Colors.green : Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (s.isActive)
              IconButton(
                tooltip: 'Huỷ ca',
                icon: const Icon(Icons.cancel, color: Colors.orange),
                onPressed: () => _cancel(s),
              ),
            IconButton(
              tooltip: 'Xoá ca',
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _delete(s),
            ),
          ],
        ),
      ),
    );
  }
}
