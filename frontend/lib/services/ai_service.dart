import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/dio_client.dart';

class AiService {
  /// Sends the symptom text (+ an optional image) for an appointment and returns
  /// the PDF bytes. Works on web and native (no dart:io path). Backend persists
  /// the report against the appointment so the doctor can fetch it later.
  Future<Uint8List> buildReport({
    Uint8List? imageBytes,
    String filename = 'symptom.jpg',
    required String symptoms,
    required int appointmentId,
  }) async {
    final form = FormData.fromMap({
      if (imageBytes != null) 'image': MultipartFile.fromBytes(imageBytes, filename: filename),
      'symptoms': symptoms,
      'appointmentId': appointmentId,
    });

    final res = await DioClient.dio.post(
      '/ai/report',
      data: form,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(List<int>.from(res.data as List));
  }
}
