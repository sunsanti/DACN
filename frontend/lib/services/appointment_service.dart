import '../core/dio_client.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/patient.dart';

class AppointmentService {
  // ---- patient profile ----
  Future<Patient> getMe() async {
    final res = await DioClient.dio.get('/patient/me');
    return Patient.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<Patient> updateMe(Map<String, dynamic> body) async {
    final res = await DioClient.dio.put('/patient/me', data: body);
    return Patient.fromJson(Map<String, dynamic>.from(res.data));
  }

  // ---- appointment detail/edit/delete ----
  Future<Appointment> getAppointment(int id) async {
    final res = await DioClient.dio.get('/patient/appointment/$id');
    return Appointment.fromJson(Map<String, dynamic>.from(res.data));
  }

  /// Reschedule to a new slot (allowed once). Confirmed appts go back to pending.
  Future<void> rescheduleAppointment(int id, {required String apTime, String? note}) async {
    await DioClient.dio.put('/patient/reschedule-appointment/$id', data: {
      'apTime': apTime,
      if (note != null) 'note': note,
    });
  }

  /// Cancel (not delete) with a reason — the row is kept so the reason is visible.
  Future<void> cancelAppointment(int id, String reason) async {
    await DioClient.dio.post('/patient/cancel-appointment/$id', data: {'reason': reason});
  }

  Future<List<Doctor>> listDoctors() async {
    final res = await DioClient.dio.get('/doctor/list');
    return (res.data as List)
        .map((e) => Doctor.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Free 30-min slots (as local DateTimes) for a doctor on a date (YYYY-MM-DD).
  Future<List<DateTime>> availability(int doctorId, String date) async {
    final res = await DioClient.dio.get('/doctor/availability',
        queryParameters: {'doctorId': doctorId, 'date': date});
    return (res.data as List)
        .map((e) => DateTime.parse(e as String).toLocal())
        .toList();
  }

  Future<List<Appointment>> listMyAppointments() async {
    final res = await DioClient.dio.get('/patient/list-appointment');
    return (res.data as List)
        .map((e) => Appointment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Appointment> create({
    required DateTime apTime,
    required String address,
    required int doctorId,
    String? note,
  }) async {
    final res = await DioClient.dio.post('/patient/create-appointment', data: {
      'apTime': apTime.toUtc().toIso8601String(),
      'address': address,
      'doctorId': doctorId,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return Appointment.fromJson(Map<String, dynamic>.from(res.data));
  }
}
