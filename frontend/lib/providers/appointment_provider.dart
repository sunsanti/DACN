import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _service = AppointmentService();

  List<Appointment> _appointments = [];
  bool _loading = false;
  String? _error;

  List<Appointment> get appointments => _appointments;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _appointments = await _service.listMyAppointments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Appointment> create({
    required DateTime apTime,
    required String address,
    required int doctorId,
    String? note,
  }) async {
    final created = await _service.create(
      apTime: apTime,
      address: address,
      doctorId: doctorId,
      note: note,
    );
    await load();
    return created;
  }
}
