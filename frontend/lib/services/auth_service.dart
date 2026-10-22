import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
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

  /// Pre-registration BHYT preview: {found:false} or {found, cardNumber (masked), rate, validTo, status}.
  Future<Map<String, dynamic>> bhytLookup(String cccd, String birthDate) async {
    final res = await DioClient.dio.post('/auth/bhyt-lookup', data: {'cccd': cccd, 'birthDate': birthDate});
    return Map<String, dynamic>.from(res.data);
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
    XFile? avatar, // optional profile photo
    required String cccd, // 12 digits; BHYT is looked up by it
  }) async {
    final res = await DioClient.dio.post('/auth/register', data: FormData.fromMap({
      'email': email,
      'password': password,
      'name': name,
      'gender': gender,
      'age': age,
      'birthDate': birthDate,
      'phone': phone,
      'address': address,
      if (avatar != null) 'avatar': await imagePart(avatar),
      'cccd': cccd,
    }));
    return AuthResult.fromJson(Map<String, dynamic>.from(res.data));
  }
}

/// Multipart file from a picked image; bytes-based so it also works on web.
Future<MultipartFile> imagePart(XFile f) async => MultipartFile.fromBytes(
      await f.readAsBytes(),
      filename: f.name,
      contentType: DioMediaType.parse(f.mimeType ?? _mimeFromName(f.name)),
    );

String _mimeFromName(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
