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

  Future<void> editAppointment(int id,
      {String? apTime, String? address, String? note}) async {
    await DioClient.dio.put('/patient/edit-appointment/$id', data: {
      if (apTime != null) 'apTime': apTime,
      if (address != null) 'address': address,
      if (note != null) 'note': note,
    });
  }

  Future<void> deleteAppointment(int id) async {
    await DioClient.dio.delete('/patient/delete-appointment/$id');
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
