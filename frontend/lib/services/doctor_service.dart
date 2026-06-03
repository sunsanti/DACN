import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/appointment.dart';

class DoctorService {
  Future<List<Appointment>> _list(String path) async {
    final res = await DioClient.dio.get(path);
    return (res.data as List)
        .map((e) => Appointment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Appointment>> listUnconfirmed() => _list('/doctor/list-unAcpappointment');
  Future<List<Appointment>> listConfirmed() => _list('/doctor/list-appointment');

  Future<void> confirm(int appointmentId,
      {required String note, required DateTime confirmDate}) async {
    await DioClient.dio.post('/doctor/confirm-appointment/$appointmentId', data: {
      'note': note,
      'confirmDate': confirmDate.toUtc().toIso8601String(),
    });
  }

  Future<void> reschedule(int appointmentId,
      {required DateTime newApTime,
      required DateTime newConfirmTime,
      required String newNote}) async {
    await DioClient.dio.post('/doctor/reAppointment/$appointmentId', data: {
      'newApTime': newApTime.toUtc().toIso8601String(),
      'newConfirmTime': newConfirmTime.toUtc().toIso8601String(),
      'newNote': newNote,
    });
  }

  Future<Uint8List> downloadReport(int appointmentId) async {
    final res = await DioClient.dio.get(
      '/doctor/report/$appointmentId',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(List<int>.from(res.data as List));
  }
}
