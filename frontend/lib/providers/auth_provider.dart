import 'package:flutter/foundation.dart';
import '../core/dio_client.dart';
import '../core/token_store.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  String? _token;
  String? _role;
  int? _patientId;
  bool _loading = true; // true while restoring persisted session

  bool get isAuthenticated => _token != null;
  bool get loading => _loading;
  String? get role => _role;
  int? get patientId => _patientId;

  AuthProvider() {
    // Auto-logout when any request returns 401.
    DioClient.onUnauthorized = logout;
    _restore();
  }

  Future<void> _restore() async {
    _token = await TokenStore.readToken();
    _role = await TokenStore.readRole();
    _patientId = await TokenStore.readPatientId();
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final r = await _auth.login(email, password);
    _token = r.accessToken;
    _role = r.role;
    _patientId = r.patientId;
    await TokenStore.write(token: r.accessToken, role: r.role, patientId: r.patientId);
    notifyListeners();
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
    );
    _token = r.accessToken;
    _role = r.role;
    _patientId = r.patientId;
    await TokenStore.write(token: r.accessToken, role: r.role, patientId: r.patientId);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _patientId = null;
    await TokenStore.clear();
    notifyListeners();
  }
}
