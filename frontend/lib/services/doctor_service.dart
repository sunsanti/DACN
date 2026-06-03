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

  Future<List<ShiftAssignment>> shiftOverview() async {
    final res = await DioClient.dio.get('/doctor/shift-overview');
    return (res.data as List)
        .map((e) => ShiftAssignment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> registerShift(int shiftId, String date) async {
    await DioClient.dio.post('/doctor/register-shift', data: {'shiftId': shiftId, 'date': date});
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
  Future<List<Appointment>> listCompleted() => _list('/doctor/list-completed');

  Future<Appointment> getDetail(int id) async {
    final res = await DioClient.dio.get('/doctor/appointment/$id');
    return Appointment.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> complete(int id) async {
    await DioClient.dio.post('/doctor/complete/$id');
  }

  Future<void> reExamination(
      {required int patientId,
      required String apTime,
      required String address,
      String? note}) async {
    await DioClient.dio.post('/doctor/re-examination', data: {
      'patientId': patientId,
      'apTime': apTime,
      'address': address,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<void> deleteAppointment(int appointmentId) async {
    await DioClient.dio.delete('/doctor/appointment/$appointmentId');
  }

  /// Reject (pending) or cancel (confirmed) with a reason -> sent to the patient.
  Future<void> cancelByDoctor(int appointmentId, String reason) async {
    await DioClient.dio.post('/doctor/cancel-appointment/$appointmentId', data: {'reason': reason});
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
