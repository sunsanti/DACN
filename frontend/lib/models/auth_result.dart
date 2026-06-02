class AuthResult {
  final String accessToken;
  final String role;
  final int? patientId;
  final int? doctorId;

  AuthResult({
    required this.accessToken,
    required this.role,
    this.patientId,
    this.doctorId,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['accessToken'] as String,
        role: json['role'] as String,
        patientId: json['patientId'] as int?,
        doctorId: json['doctorId'] as int?,
      );
}
