import 'package:flutter/material.dart';

import '../core/dio_client.dart';
import '../core/shift_ui.dart';
import '../core/ui.dart';
import '../models/shift.dart';
import '../services/doctor_service.dart';
import 'shift_overview_screen.dart';

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


  Future<void> _register() async {
    // Date first, so the dialog can show which shifts are already full that day.
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Chọn ngày làm ca',
    );
    if (date == null) return;
    final dateStr = fmtYmd(date);
    List<ShiftTemplate> templates;
    try {
      templates = await _service.shiftTemplates(date: dateStr);
    } catch (e) {
      toast(DioClient.messageFrom(e));
      return;
    }
    if (!mounted) return;
    final picked = await showDialog<ShiftTemplate>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Chọn ca trực ngày $dateStr'),
        children: templates
            .map((t) => SimpleDialogOption(
                  onPressed: t.isFull ? null : () => Navigator.pop(ctx, t),
                  child: Text(
                    '${t.typeLabel} (${t.hours.toStringAsFixed(0)}h)'
                    '${t.capacity == null ? '' : ' · ${t.registered}/${t.capacity}'}'
                    '${t.isFull ? ' · Đã đủ người' : ''}',
                    style: t.isFull ? const TextStyle(color: Colors.grey) : null,
                  ),
                ))
            .toList(),
      ),
    );
    if (picked == null || !mounted) return;
    try {
      await _service.registerShift(picked.id, dateStr);
      toast('Đã đăng ký ca ${picked.typeLabel} ngày $dateStr');
      await _load();
    } catch (e) {
      toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _cancel(ShiftAssignment s) async {
    try {
      await _service.cancelAssignment(s.id);
      toast('Đã huỷ ca #${s.id}');
      await _load();
    } catch (e) {
      toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _delete(ShiftAssignment s) async {
    try {
      await _service.deleteAssignment(s.id);
      toast('Đã xoá ca #${s.id}');
      await _load();
    } catch (e) {
      toast(DioClient.messageFrom(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ca trực của tôi'),
        actions: [
          IconButton(
            tooltip: 'Tất cả ca trực',
            icon: const Icon(Icons.groups),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShiftOverviewScreen()),
            ),
          ),
        ],
      ),
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
        leading: Icon(shiftIcon(s.type),
            color: canceled ? Colors.grey : Colors.orange),
        title: Text('Ca ${s.typeLabel} — ${s.dateLabel}'),
        subtitle: Text('${s.timeLabel} · ${fmtHours(s.duration)} · ${s.statusLabel}',
            style: TextStyle(color: s.isActive ? Colors.green : Colors.grey)),
        trailing: s.isDone
            ? const Tooltip(
                message: 'Đã hoàn thành',
                child: Icon(Icons.check_circle, color: Colors.green),
              )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (s.isActive)
              IconButton(
                tooltip: 'Huỷ ca',
                icon: const Icon(Icons.cancel, color: Colors.orange),
                onPressed: () => _cancel(s),
              ),
            // Delete (= move to another day) only before the shift starts; running,
            // ended or canceled shifts keep their worked hours, so they can only be canceled.
            if (s.isActive && s.startTime.isAfter(DateTime.now()))
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
