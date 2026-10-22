import '../core/dio_client.dart';
import '../models/appointment.dart';

/// VietQR details returned when the patient picks QR.
class QrInfo {
  final String payload; // VietQR string to render
  final String bankName;
  final String accountNo;
  final String accountName;
  final int amount;
  final String content; // transfer note, e.g. DACN17

  QrInfo.fromJson(Map<String, dynamic> j)
      : payload = j['payload'] as String,
        bankName = (j['bankName'] ?? '') as String,
        accountNo = (j['accountNo'] ?? '') as String,
        accountName = (j['accountName'] ?? '') as String,
        amount = (j['amount'] as num).toInt(),
        content = (j['content'] ?? '') as String;
}

/// Admin inbox item (money received / transfer to check).
class AdminNotification {
  final int id;
  final String title;
  final String body;
  final int? appointmentId;
  final bool read;
  final DateTime createdAt;

  AdminNotification.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        title = (j['title'] ?? '') as String,
        body = (j['body'] ?? '') as String,
        appointmentId = j['appointmentId'] as int?,
        read = j['readAt'] != null,
        createdAt = DateTime.parse(j['createdAt'] as String).toLocal();
}

class PaymentService {
  /// Patient picks 'cash' or 'qr'; QR comes back with the VietQR payload.
  Future<QrInfo?> pay(int appointmentId, String method) async {
    final res = await DioClient.dio
        .post('/patient/appointment/$appointmentId/pay', data: {'method': method});
    final qr = res.data['qr'];
    return qr is Map ? QrInfo.fromJson(Map<String, dynamic>.from(qr)) : null;
  }

  // ---- admin ----
  Future<List<Appointment>> payments(String status) async {
    final res = await DioClient.dio.get('/admin/payments', queryParameters: {'status': status});
    return (res.data as List).map((e) => Appointment.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> confirm(int appointmentId) async {
    await DioClient.dio.post('/admin/payments/$appointmentId/confirm');
  }

  Future<List<AdminNotification>> notifications() async {
    final res = await DioClient.dio.get('/admin/notifications');
    return (res.data as List)
        .map((e) => AdminNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<int> unreadCount() async {
    final res = await DioClient.dio.get('/admin/notifications/unread-count');
    return (res.data['count'] as num).toInt();
  }

  Future<void> readAll() async {
    await DioClient.dio.post('/admin/notifications/read-all');
  }
}
