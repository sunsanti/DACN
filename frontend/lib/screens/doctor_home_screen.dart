import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../core/pdf_opener.dart';
import '../core/reason_dialog.dart';
import '../core/billing_ui.dart';
import '../core/ui.dart';
import '../models/appointment.dart';
import '../models/shift.dart';
import '../providers/auth_provider.dart';
import '../providers/doctor_provider.dart';
import '../services/doctor_service.dart';
import 'doctor_shifts_screen.dart';
import 'doctor_appointment_detail_screen.dart';
import 're_examination_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final _docService = DoctorService();
  List<ShiftAssignment>? _shifts; // null = not loaded / failed → generic subtitle on the shift card

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().load();
    });
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    try {
      final shifts = await _docService.myShifts();
      if (mounted) setState(() => _shifts = shifts);
    } catch (_) {
      // the card still works without today's shifts
    }
  }

  Future<void> _confirm(Appointment a) async {
    final provider = context.read<DoctorProvider>();
    final noteCtrl = TextEditingController(text: a.doctorNote ?? '');
    DateTime confirmDate = DateTime.now();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận lịch #${a.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú cho bệnh nhân'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await provider.confirm(a.id, note: noteCtrl.text.trim(), confirmDate: confirmDate);
      _toast('Đã xác nhận lịch #${a.id}');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _cancelByDoctor(Appointment a, String title) async {
    final provider = context.read<DoctorProvider>();
    final reason = await promptReason(context,
        title: title, hint: 'Lý do (gửi cho bệnh nhân)', confirmLabel: 'Xác nhận');
    if (reason == null) return;
    try {
      await provider.cancelByDoctor(a.id, reason);
      _toast('Đã gửi tới bệnh nhân');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _rescheduleDoctor(Appointment a) async {
    if (a.doctorId == null) return;
    final provider = context.read<DoctorProvider>();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Chọn ngày dời lịch',
    );
    if (date == null || !mounted) return;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    List<DateTime> slots;
    try {
      slots = await _docService.availability(a.doctorId!, dateStr);
    } catch (e) {
      _toast(DioClient.messageFrom(e));
      return;
    }
    if (!mounted) return;
    if (slots.isEmpty) {
      _toast('Bạn chưa có khung trống ngày này (đăng ký ca trước)');
      return;
    }
    final slot = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Chọn khung giờ mới'),
        children: slots
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s),
                  child: Text(
                      '${s.day}/${s.month} — ${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}'),
                ))
            .toList(),
      ),
    );
    if (slot == null) return;
    try {
      await provider.reschedule(a.id, slot.toUtc().toIso8601String());
      _toast('Đã dời lịch #${a.id}');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _complete(Appointment a) async {
    final provider = context.read<DoctorProvider>();
    final ids = await pickDiseases(context);
    if (ids == null) return;
    try {
      await provider.complete(a.id, ids);
      _toast('Đã đánh dấu khám xong lịch #${a.id}');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  Future<void> _reExam(Appointment a) async {
    if (a.patientId == null || a.doctorId == null) {
      _toast('Thiếu thông tin bệnh nhân');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReExaminationScreen(
          doctorId: a.doctorId!,
          patientId: a.patientId!,
          patientName: a.patientName,
          defaultAddress: a.address,
        ),
      ),
    );
  }

  Future<void> _openReport(Appointment a) async {
    try {
      final pdf = await _docService.downloadReport(a.id);
      final path = await openPdf(pdf, 'report-${a.id}.pdf');
      _toast(path != null ? 'Đã mở báo cáo' : 'Đã tải báo cáo (xem ở tab mới/Downloads)');
    } catch (e) {
      _toast(DioClient.messageFrom(e));
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorProvider>();
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    bool isToday(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;
    final today = [...provider.pending, ...provider.confirmed].where((a) => isToday(a.apTime)).length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const SessionTitle('Bác sĩ'),
          actions: [
            IconButton(
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Header: today's numbers on the primary color, continuing the AppBar.
            Container(
              color: cs.primary,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  _stat('${provider.pending.length}', 'Chờ xác nhận'),
                  const SizedBox(width: 8),
                  _stat('$today', 'Lịch hôm nay'),
                  const SizedBox(width: 8),
                  _stat('${provider.completed.length}', 'Đã khám'),
                ],
              ),
            ),
            // Shift card straddles the header: top half of its background is primary.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.primary, cs.primary, Colors.transparent, Colors.transparent],
                  stops: const [0, 0.5, 0.5, 1],
                ),
              ),
              child: _shiftCard(),
            ),
            const SizedBox(height: 4),
            TabBar(
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              indicatorColor: cs.primary,
              tabs: [
                Tab(text: 'Chờ (${provider.pending.length})'),
                Tab(text: 'Đã xác nhận (${provider.confirmed.length})'),
                Tab(text: 'Đã khám (${provider.completed.length})'),
              ],
            ),
            Expanded(
              child: provider.loading &&
                      provider.pending.isEmpty &&
                      provider.confirmed.isEmpty &&
                      provider.completed.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _list(provider.pending),
                        _list(provider.confirmed),
                        _list(provider.completed),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    final on = Theme.of(context).colorScheme.onPrimary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: on.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: on, fontSize: 22, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(color: on.withValues(alpha: 0.85), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// "Ca làm của tôi": one tap to the shift screen; subtitle = today's active shifts.
  Widget _shiftCard() {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final todays = (_shifts ?? [])
        .where((s) =>
            s.isActive &&
            s.startTime.year == now.year &&
            s.startTime.month == now.month &&
            s.startTime.day == now.day)
        .toList();
    final subtitle = _shifts == null
        ? 'Đăng ký và xem ca trực'
        : todays.isEmpty
            ? 'Hôm nay không có ca'
            : 'Hôm nay: ${todays.map((s) => 'Ca ${s.typeLabel.toLowerCase()} ${fmtTime(s.startTime)}–${fmtTime(s.endTime)}').join(', ')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.calendar_month, color: cs.onPrimaryContainer),
          ),
          title: const Text('Ca làm của tôi', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: Icon(Icons.chevron_right, color: cs.primary),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DoctorShiftsScreen()),
            );
            _loadShifts();
          },
        ),
      ),
    );
  }

  Widget _list(List<Appointment> items) {
    return RefreshIndicator(
      onRefresh: () => Future.wait([context.read<DoctorProvider>().load(), _loadShifts()]),
      child: items.isEmpty
          ? const EmptyState(Icons.inbox_outlined, 'Không có lịch hẹn nào')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _tile(items[i]),
            ),
    );
  }

  /// Secondary actions for [a], shown in the "⋯" bottom sheet. Red ones still ask for a reason.
  List<(IconData, String, bool, VoidCallback)> _moreActions(Appointment a) => [
        if (a.isConfirmed && a.canReschedule)
          (Icons.edit_calendar, 'Dời lịch', false, () => _rescheduleDoctor(a)),
        if (!a.isExamined) (Icons.description, 'Báo cáo AI', false, () => _openReport(a)),
        if (a.isPending)
          (Icons.block, 'Không nhận bệnh', true, () => _cancelByDoctor(a, 'Không nhận bệnh #${a.id}')),
        if (a.isConfirmed)
          (Icons.cancel, 'Hủy lịch', true, () => _cancelByDoctor(a, 'Hủy lịch #${a.id}')),
      ];

  Future<void> _showMore(Appointment a) async {
    final actions = _moreActions(a);
    final picked = await showModalBottomSheet<VoidCallback>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, label, danger, run) in actions)
              ListTile(
                leading: Icon(icon, color: danger ? Colors.red : null),
                title: Text(label, style: TextStyle(color: danger ? Colors.red : null)),
                onTap: () => Navigator.pop(ctx, run),
              ),
          ],
        ),
      ),
    );
    picked?.call(); // run after the sheet closes so dialogs open on the screen's context
  }

  Widget _tile(Appointment a) {
    void openDetail() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DoctorAppointmentDetailScreen(appointmentId: a.id)),
        );
    return Card(
      child: InkWell(
        onTap: openDetail,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(avatarUrl: a.patientAvatar, name: a.patientName, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.patientName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('${fmtDateTime(a.apTime)}  ·  Lịch #${a.id}',
                            style: TextStyle(
                                fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  StatusChip(a),
                  const SizedBox(width: 8),
                ],
              ),
              InfoLine(Icons.place_outlined, a.address),
              if (a.note != null && a.note!.isNotEmpty) InfoLine(Icons.notes, a.note!),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (a.isPending)
                    FilledButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Xác nhận'),
                      onPressed: () => _confirm(a),
                    ),
                  if (a.isConfirmed)
                    FilledButton.icon(
                      icon: const Icon(Icons.task_alt, size: 18),
                      label: const Text('Đã khám xong'),
                      onPressed: () => _complete(a),
                    ),
                  if (a.isExamined)
                    FilledButton.icon(
                      icon: const Icon(Icons.event_repeat, size: 18),
                      label: const Text('Tái khám'),
                      onPressed: () => _reExam(a),
                    ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(onPressed: openDetail, child: const Text('Chi tiết')),
                  const Spacer(),
                  if (_moreActions(a).isNotEmpty)
                    IconButton(
                      tooltip: 'Thêm thao tác',
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => _showMore(a),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
