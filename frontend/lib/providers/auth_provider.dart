import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/auth_result.dart';
import '../core/dio_client.dart';
import '../core/token_store.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  String? _token;
  String? _role;
  int? _patientId;
  String _name = '';
  String? _avatarUrl;
  bool _loading = true; // true while restoring persisted session

  bool get isAuthenticated => _token != null;
  bool get loading => _loading;
  String? get role => _role;
  int? get patientId => _patientId;
  String get name => _name;
  String? get avatarUrl => _avatarUrl;

  AuthProvider() {
    // Auto-logout when any request returns 401.
    DioClient.onUnauthorized = logout;
    _restore();
  }

  Future<void> _restore() async {
    _token = await TokenStore.readToken();
    _role = await TokenStore.readRole();
    _patientId = await TokenStore.readPatientId();
    _name = await TokenStore.readName() ?? '';
    _avatarUrl = await TokenStore.readAvatarUrl();
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final r = await _auth.login(email, password);
    await _setSession(r);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String gender,
    required int age,
    required String birthDate,
    required String phone,
    required String address,
    XFile? avatar,
    required String cccd,
  }) async {
    final r = await _auth.register(
      email: email,
      password: password,
      name: name,
      gender: gender,
      age: age,
      birthDate: birthDate,
      phone: phone,
      address: address,
      avatar: avatar,
      cccd: cccd,
    );
    await _setSession(r);
  }

  Future<void> _setSession(AuthResult r) async {
    _token = r.accessToken;
    _role = r.role;
    _patientId = r.patientId;
    _name = r.name;
    _avatarUrl = r.avatarUrl;
    await TokenStore.write(
      token: r.accessToken,
      role: r.role,
      patientId: r.patientId,
      name: r.name,
      avatarUrl: r.avatarUrl,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _patientId = null;
    _name = '';
    _avatarUrl = null;
    await TokenStore.clear();
    notifyListeners();
  }
}
