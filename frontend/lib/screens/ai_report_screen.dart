import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/dio_client.dart';
import '../core/pdf_opener.dart';
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

  Uint8List? _imageBytes;
  String _imageName = 'symptom.jpg';
  bool _submitting = false;
  String? _resultMessage;

  @override
  void dispose() {
    _symptoms.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1280);
    if (picked != null) {
      final bytes = await picked.readAsBytes(); // works on web + native
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
      });
    }
  }

  Future<void> _submit() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn ảnh trước')),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _resultMessage = null;
    });
    try {
      final Uint8List pdf = await _ai.buildReport(
        imageBytes: _imageBytes!,
        filename: _imageName,
        symptoms: _symptoms.text.trim(),
        appointmentId: widget.appointment.id,
      );
      final path = await openPdf(pdf, 'ai-report-${widget.appointment.id}.pdf');
      setState(() => _resultMessage =
          path != null ? 'Đã lưu & mở PDF: $path' : 'Đã mở PDF ở tab mới');
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
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_imageBytes!, height: 200, fit: BoxFit.cover),
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
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Text(_resultMessage!, style: const TextStyle(color: Colors.green)),
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
