import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../services/appointment_service.dart';
import 'dio_client.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
String fmtTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
String fmtDateTime(DateTime d) => '${fmtDate(d)} ${fmtTime(d)}';

/// API date format: yyyy-MM-dd.
String fmtYmd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

extension StateToast on State {
  /// Short SnackBar message; no-op once the screen is gone.
  void toast(String msg) {
    if (mounted) _snack(context, msg);
  }
}

/// Pick a date (next 90 days), then one of [doctorId]'s free 30-min slots.
/// Null when cancelled or nothing is free (the user already got a toast).
Future<DateTime?> pickFreeSlot(
  BuildContext context,
  int doctorId, {
  required String dateHelp,
  required String noSlotMsg,
}) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: now,
    lastDate: now.add(const Duration(days: 90)),
    helpText: dateHelp,
  );
  if (date == null || !context.mounted) return null;
  List<DateTime> slots;
  try {
    slots = await AppointmentService().availability(doctorId, fmtYmd(date));
  } catch (e) {
    if (context.mounted) _snack(context, DioClient.messageFrom(e));
    return null;
  }
  if (!context.mounted) return null;
  if (slots.isEmpty) {
    _snack(context, noSlotMsg);
    return null;
  }
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Chọn khung giờ mới'),
      children: [
        for (final s in slots)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, s),
            child: Text('${s.day}/${s.month} — ${fmtTime(s)}'),
          ),
      ],
    ),
  );
}

/// 1234567 → "1.234.567 đ".
String fmtMoney(int v) {
  final s = v.abs().toString();
  final buf = StringBuffer(v < 0 ? '−' : '');
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '$buf đ';
}

String fmtHours(num h) => h % 1 == 0 ? '${h.toInt()}h' : '${h.toStringAsFixed(2)}h';

/// Colored pill for an appointment's status.
class StatusChip extends StatelessWidget {
  final Appointment appointment;
  const StatusChip(this.appointment, {super.key});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final color = a.isCanceled
        ? Colors.red.shade700
        : a.isExamined
            ? Colors.blue.shade700
            : a.isConfirmed
                ? Colors.green.shade700
                : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(a.statusLabel,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Icon + label row used inside cards.
class InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const InfoLine(this.icon, this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: c, fontSize: 13.5))),
        ],
      ),
    );
  }
}

/// Scrollable (so pull-to-refresh still works) empty / error placeholder.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.outline;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: c),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: c)),
      ],
    );
  }
}

/// Full URL for a server-relative upload path (`/uploads/...`), or null if empty.
String? imageUrl(String? path) =>
    (path == null || path.isEmpty) ? null : '${ApiConfig.baseUrl}$path';

/// Round avatar: the uploaded photo, or the name's first letter as fallback.
class UserAvatar extends StatefulWidget {
  final String? avatarUrl; // server path, e.g. /uploads/avatars/x.jpg
  final String name;
  final double radius;
  const UserAvatar({super.key, this.avatarUrl, required this.name, this.radius = 20});

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _failed = false;

  @override
  void didUpdateWidget(UserAvatar old) {
    super.didUpdateWidget(old);
    if (old.avatarUrl != widget.avatarUrl) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl(widget.avatarUrl);
    final name = widget.name.trim();
    if (url != null && !_failed) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, _) => setState(() => _failed = true),
      );
    }
    return CircleAvatar(
      radius: widget.radius,
      child: name.isEmpty
          ? Icon(Icons.person, size: widget.radius)
          : Text(name[0].toUpperCase(), style: TextStyle(fontSize: widget.radius * 0.8)),
    );
  }
}

/// Tap-to-pick round photo with preview; the X button clears it.
class AvatarPicker extends StatefulWidget {
  final ValueChanged<XFile?> onChanged;
  final String? errorText;
  final double radius;
  const AvatarPicker({super.key, required this.onChanged, this.errorText, this.radius = 48});

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  Uint8List? _bytes;

  Future<void> _pick() async {
    final f = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() => _bytes = bytes);
    widget.onChanged(f);
  }

  void _clear() {
    setState(() => _bytes = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              customBorder: const CircleBorder(),
              onTap: _pick,
              child: CircleAvatar(
                radius: widget.radius,
                backgroundColor: cs.surfaceContainerHighest,
                backgroundImage: _bytes == null ? null : MemoryImage(_bytes!),
                child: _bytes == null
                    ? Icon(Icons.add_a_photo_outlined, size: widget.radius * 0.6, color: cs.primary)
                    : null,
              ),
            ),
            if (_bytes != null)
              Positioned(
                right: -4,
                top: -4,
                child: IconButton.filledTonal(
                  tooltip: 'Bỏ ảnh',
                  iconSize: 16,
                  onPressed: _clear,
                  icon: const Icon(Icons.close),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(_bytes == null ? 'Chọn ảnh đại diện' : 'Bấm để đổi ảnh',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(widget.errorText!, style: TextStyle(color: cs.error, fontSize: 12.5)),
          ),
      ],
    );
  }
}

/// AppBar title for home screens: the logged-in user's avatar + greeting + screen name.
class SessionTitle extends StatelessWidget {
  final String subtitle;
  const SessionTitle(this.subtitle, {super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        UserAvatar(avatarUrl: auth.avatarUrl, name: auth.name, radius: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Xin chào, ${auth.name}', style: t.titleMedium, overflow: TextOverflow.ellipsis),
              Text(subtitle, style: t.bodySmall, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

/// Round icon "bubble" with a label underneath and an optional count badge (home shortcuts).
class Bubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color; // icon color; the circle is a light tint of it
  final int badge;
  final VoidCallback onTap;
  const Bubble(this.icon, this.label,
      {super.key, required this.color, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text(badge > 99 ? '99+' : '$badge'),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.2)),
          ],
        ),
      ),
    );
  }
}
