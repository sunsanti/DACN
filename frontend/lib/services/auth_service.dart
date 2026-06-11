import '../core/dio_client.dart';
import '../models/auth_result.dart';

class AuthService {
  Future<AuthResult> login(String email, String password) async {
    final res = await DioClient.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required String gender,
    required int age,
    required String birthDate, // ISO yyyy-MM-dd
    required String phone,
    required String address,
  }) async {
    final res = await DioClient.dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
      'gender': gender,
      'age': age,
      'birthDate': birthDate,
      'phone': phone,
      'address': address,
    });
    return AuthResult.fromJson(Map<String, dynamic>.from(res.data));
  }
}
