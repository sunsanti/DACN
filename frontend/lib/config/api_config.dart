class ApiConfig {
  /// Base URL of the NestJS backend.
  ///
  /// - Android emulator: the host machine is reachable at 10.0.2.2 (NOT localhost).
  /// - iOS simulator: localhost works.
  /// - Real device: use your machine's LAN IP, e.g. http://192.168.1.10:3000
  ///
  /// Override at run time without editing code:
  ///   flutter run --dart-define=API_BASE=http://192.168.1.10:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
