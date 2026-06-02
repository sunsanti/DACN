import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../core/dio_client.dart';
import '../models/appointment.dart';
import '../services/ai_service.dart';

class AiReportScreen extends StatefulWidget {
  final Appointment appointment;
  const AiReportScreen({super.key, required this.appointment});

  @override
  State<AiReportScreen> createState() => _AiReportScreenState();
}

class _AiReportScreenState extends State<AiReportScreen> {
  final _symptoms = TextEditingController();
  final _picker = ImagePicker();
  final _ai = AiService();

  XFile? _image;
  bool _submitting = false;
  String? _savedPdfPath;

  @override
  void dispose() {
    _symptoms.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1280);
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _submit() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn ảnh trước')),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _savedPdfPath = null;
    });
    try {
      final Uint8List pdf = await _ai.buildReport(
        imagePath: _image!.path,
        symptoms: _symptoms.text.trim(),
        appointmentId: widget.appointment.id,
      );
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/ai-report-${widget.appointment.id}.pdf';
      await File(path).writeAsBytes(pdf, flush: true);
      setState(() => _savedPdfPath = path);
      await OpenFilex.open(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(DioClient.messageFrom(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI — Lịch #${widget.appointment.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bác sĩ: ${widget.appointment.doctorName}'),
            const SizedBox(height: 12),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_image!.path), height: 200, fit: BoxFit.cover),
              )
            else
              Container(
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Chưa chọn ảnh'),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Thư viện'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp ảnh'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _symptoms,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mô tả triệu chứng',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.smart_toy),
              label: Text(_submitting ? 'Đang phân tích...' : 'Gửi cho AI & tạo PDF'),
            ),
            if (_savedPdfPath != null) ...[
              const SizedBox(height: 16),
              Text('Đã lưu PDF: $_savedPdfPath', style: const TextStyle(color: Colors.green)),
              TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở lại PDF'),
                onPressed: () => OpenFilex.open(_savedPdfPath!),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: lần đầu gọi AI có thể chậm vài giây (tải mô hình). '
              'Kết quả chỉ mang tính tham khảo.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
