import 'package:flutter/foundation.dart';
import '../models/doctor_salary.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  List<DoctorSalary> _salaries = [];
  bool _loading = false;
  String? _error;

  List<DoctorSalary> get salaries => _salaries;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _salaries = await _service.doctorSalaries();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addDoctor({
    required String email,
    required String password,
    required String name,
    required int age,
    required String dateOfBirth,
    required String gender,
    required String phone,
    required String address,
  }) async {
    await _service.addDoctor(
      email: email,
      password: password,
      name: name,
      age: age,
      dateOfBirth: dateOfBirth,
      gender: gender,
      phone: phone,
      address: address,
    );
    await load();
  }
}
