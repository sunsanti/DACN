import 'package:shared_preferences/shared_preferences.dart';

/// Persists the auth token + role + patientId across app launches.
class TokenStore {
  static const _kToken = 'auth_token';
  static const _kRole = 'auth_role';
  static const _kPatientId = 'auth_patient_id';
  static const _kName = 'auth_name';
  static const _kAvatar = 'auth_avatar';

  static Future<void> write({
    required String token,
    required String role,
    int? patientId,
    String name = '',
    String? avatarUrl,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setString(_kRole, role);
    await p.setString(_kName, name);
    if (avatarUrl != null) {
      await p.setString(_kAvatar, avatarUrl);
    } else {
      await p.remove(_kAvatar);
    }
    if (patientId != null) {
      await p.setInt(_kPatientId, patientId);
    } else {
      await p.remove(_kPatientId);
    }
  }

  static Future<String?> readToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kToken);
  }

  static Future<String?> readRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRole);
  }

  static Future<int?> readPatientId() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kPatientId);
  }

  static Future<String?> readName() async =>
      (await SharedPreferences.getInstance()).getString(_kName);

  static Future<String?> readAvatarUrl() async =>
      (await SharedPreferences.getInstance()).getString(_kAvatar);

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kRole);
    await p.remove(_kPatientId);
    await p.remove(_kName);
    await p.remove(_kAvatar);
  }
}
