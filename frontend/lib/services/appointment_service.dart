import '../core/dio_client.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';

class AppointmentService {
  Future<List<Doctor>> listDoctors() async {
    final res = await DioClient.dio.get('/doctor/list');
    return (res.data as List)
        .map((e) => Doctor.fromJson(Map<String, dynamic>.from(e)))
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
