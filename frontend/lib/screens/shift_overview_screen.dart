import 'package:flutter/material.dart';

import '../core/dio_client.dart';
import '../core/shift_ui.dart';
import '../models/shift.dart';
import '../services/doctor_service.dart';

class ShiftOverviewScreen extends StatefulWidget {
  const ShiftOverviewScreen({super.key});

  @override
  State<ShiftOverviewScreen> createState() => _ShiftOverviewScreenState();
}

class _ShiftOverviewScreenState extends State<ShiftOverviewScreen> {
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
      _shifts = await _service.shiftOverview();
      _error = null;
    } catch (e) {
      _error = DioClient.messageFrom(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tất cả ca trực')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [const SizedBox(height: 120), Center(child: Text('Lỗi: $_error'))])
                : _shifts.isEmpty
                    ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Chưa có ca trực nào'))])
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _shifts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final s = _shifts[i];
                          return Card(
                            child: ListTile(
                              leading: Icon(shiftIcon(s.type), color: Colors.orange),
                              title: Text('BS. ${s.doctorName} — ${s.dateLabel}'),
                              subtitle: Text(
                                  'Ca ${s.typeLabel} · ${s.timeLabel} · ${s.duration.toStringAsFixed(1)}h'),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
