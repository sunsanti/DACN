import '../core/dio_client.dart';
import '../models/doctor_salary.dart';

class AdminService {
  Future<List<DoctorSalary>> doctorSalaries() async {
    final res = await DioClient.dio.get('/admin/doctor-salaries');
    return (res.data as List)
        .map((e) => DoctorSalary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Admin creates a doctor account (reuses /auth/register-doctor).
  Future<void> addDoctor({
    required String email,
    required String password,
    required String name,
    required int age,
    required String dateOfBirth, // yyyy-MM-dd
    required String gender,
    required String phone,
    required String address,
  }) async {
    await DioClient.dio.post('/auth/register-doctor', data: {
      'email': email,
      'password': password,
      'name': name,
      'age': age,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phone': phone,
      'address': address,
    });
  }
}
