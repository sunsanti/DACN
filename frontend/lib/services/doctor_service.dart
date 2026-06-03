import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/appointment.dart';
import '../models/shift.dart';

class DoctorService {
  // ---- shifts ----
  Future<List<ShiftTemplate>> shiftTemplates() async {
    final res = await DioClient.dio.get('/doctor/shift-templates');
    return (res.data as List)
        .map((e) => ShiftTemplate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ShiftAssignment>> myShifts() async {
    final res = await DioClient.dio.get('/doctor/my-shifts');
    return (res.data as List)
        .map((e) => ShiftAssignment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> registerShift(int shiftId) async {
    await DioClient.dio.post('/doctor/register-shift', data: {'shiftId': shiftId});
  }

  Future<void> cancelAssignment(int id) async {
    await DioClient.dio.post('/doctor/cancel-assignment/$id');
  }

  Future<void> deleteAssignment(int id) async {
    await DioClient.dio.delete('/doctor/assignment/$id');
  }

  Future<List<Appointment>> _list(String path) async {
    final res = await DioClient.dio.get(path);
    return (res.data as List)
        .map((e) => Appointment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Appointment>> listUnconfirmed() => _list('/doctor/list-unAcpappointment');
  Future<List<Appointment>> listConfirmed() => _list('/doctor/list-appointment');

  Future<void> deleteAppointment(int appointmentId) async {
    await DioClient.dio.delete('/doctor/appointment/$appointmentId');
  }

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
