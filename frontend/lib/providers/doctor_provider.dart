import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/doctor_service.dart';

class DoctorProvider extends ChangeNotifier {
  final DoctorService _service = DoctorService();

  List<Appointment> _pending = [];
  List<Appointment> _confirmed = [];
  List<Appointment> _completed = [];
  bool _loading = false;
  String? _error;

  List<Appointment> get pending => _pending;
  List<Appointment> get confirmed => _confirmed;
  List<Appointment> get completed => _completed;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.listUnconfirmed(),
        _service.listConfirmed(),
        _service.listCompleted(),
      ]);
      _pending = results[0];
      _confirmed = results[1];
      _completed = results[2];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> confirm(int id, {required String note, required DateTime confirmDate}) async {
    await _service.confirm(id, note: note, confirmDate: confirmDate);
    await load();
  }

  Future<void> complete(int id) async {
    await _service.complete(id);
    await load();
  }

  Future<void> cancelByDoctor(int id, String reason) async {
    await _service.cancelByDoctor(id, reason);
    await load();
  }

  Future<void> reExamination(
      {required int patientId,
      required String apTime,
      required String address,
      String? note}) async {
    await _service.reExamination(
        patientId: patientId, apTime: apTime, address: address, note: note);
    await load();
  }

}
