import '../core/dio_client.dart';
import '../models/doctor_salary.dart';
import '../models/doctor_detail.dart';

class AdminService {
  Future<List<DoctorSalary>> doctorSalaries() async {
    final res = await DioClient.dio.get('/admin/doctor-salaries');
    return (res.data as List)
        .map((e) => DoctorSalary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<DoctorDetail> getDoctor(int id) async {
    final res = await DioClient.dio.get('/doctor/detail/$id');
    return DoctorDetail.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> updateDoctor(int id, Map<String, dynamic> body) async {
    await DioClient.dio.put('/doctor/update/$id', data: body);
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
