import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/doctor_service.dart';

class DoctorProvider extends ChangeNotifier {
  final DoctorService _service = DoctorService();

  List<Appointment> _pending = [];
  List<Appointment> _confirmed = [];
  bool _loading = false;
  String? _error;

  List<Appointment> get pending => _pending;
  List<Appointment> get confirmed => _confirmed;
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
      ]);
      _pending = results[0];
      _confirmed = results[1];
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

  Future<void> reschedule(int id,
      {required DateTime newApTime,
      required DateTime newConfirmTime,
      required String newNote}) async {
    await _service.reschedule(id,
        newApTime: newApTime, newConfirmTime: newConfirmTime, newNote: newNote);
    await load();
  }
}
