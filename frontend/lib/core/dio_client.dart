import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_store.dart';

/// Shared Dio instance. Attaches the JWT to every request and notifies a
/// registered handler when the server returns 401 (so the app can log out).
class DioClient {
  static void Function()? onUnauthorized;

  static final Dio dio = _build();

  static Dio _build() {
    final d = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60), // AI model can be slow
      ),
    );

    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStore.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(e);
        },
      ),
    );

    return d;
  }

  /// Best-effort extraction of a human message from a DioException.
  static String messageFrom(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final m = data['message'];
        return m is List ? m.join(', ') : m.toString();
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Không kết nối được máy chủ (${ApiConfig.baseUrl}). '
            'Kiểm tra backend đang chạy. Web/iOS dùng localhost, '
            'emulator Android dùng 10.0.2.2.';
      }
      return error.message ?? 'Lỗi không xác định';
    }
    return error.toString();
  }
}
