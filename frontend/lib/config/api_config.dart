import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Optional compile-time override:
  ///   flutter run --dart-define=API_BASE=http://192.168.1.10:3000
  static const String _override = String.fromEnvironment('API_BASE');

  /// Base URL of the NestJS backend, chosen per platform:
  /// - Web (Chrome) / iOS sim / desktop: localhost
  /// - Android emulator: 10.0.2.2 (its alias for the host machine)
  /// - Real device: pass --dart-define=API_BASE=http://YOUR_LAN_IP:3000
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}
