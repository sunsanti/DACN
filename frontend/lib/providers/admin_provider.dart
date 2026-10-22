import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/doctor_salary.dart';
import '../models/disease.dart';
import '../models/news.dart';
import '../services/admin_service.dart';
import '../services/disease_service.dart';
import '../services/news_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();
  final NewsService _newsService = NewsService();

  List<News> news = [];

  final DiseaseService _diseaseService = DiseaseService();
  PriceList? prices;

  Future<void> loadPrices() async {
    prices = await _diseaseService.list();
    notifyListeners();
  }

  Future<void> addDisease(String name, int price, {bool bhytCovered = true}) async {
    await _diseaseService.create(name, price, bhytCovered: bhytCovered);
    await loadPrices();
  }

  Future<void> updateDisease(int id, {String? name, int? price, bool? active, bool? bhytCovered}) async {
    await _diseaseService.update(id, name: name, price: price, active: active, bhytCovered: bhytCovered);
    await loadPrices();
  }

  Future<void> loadNews() async {
    news = await _newsService.list();
    notifyListeners();
  }

  Future<void> addNews(String title, String url, XFile image) async {
    await _newsService.create(title, url, image);
    await loadNews();
  }

  Future<void> deleteNews(int id) async {
    await _newsService.delete(id);
    await loadNews();
  }

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
    required XFile avatar,
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
      avatar: avatar,
    );
    await load();
  }
}
