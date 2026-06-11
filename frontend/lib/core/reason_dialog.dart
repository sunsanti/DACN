import 'package:flutter/material.dart';

/// Prompts for a non-empty reason. Returns the reason, or null if cancelled.
Future<String?> promptReason(
  BuildContext context, {
  required String title,
  String hint = 'Nhập lý do',
  String confirmLabel = 'Xác nhận',
}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        maxLines: 2,
        autofocus: true,
        decoration: InputDecoration(labelText: hint, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        FilledButton(
          onPressed: () {
            final r = ctrl.text.trim();
            if (r.isEmpty) return;
            Navigator.pop(ctx, r);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
