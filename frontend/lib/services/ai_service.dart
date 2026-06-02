import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/dio_client.dart';

class AiService {
  /// Sends the symptom image + text for an appointment and returns the PDF bytes.
  /// Backend persists the report against the appointment (doctor can fetch later).
  Future<Uint8List> buildReport({
    required String imagePath,
    required String symptoms,
    required int appointmentId,
  }) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'symptom.jpg'),
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
