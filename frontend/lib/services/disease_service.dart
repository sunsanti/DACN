import '../core/dio_client.dart';
import '../models/disease.dart';

class DiseaseService {
  /// Doctor: active only; admin: all. Includes the fixed exam fee.
  Future<PriceList> list() async {
    final res = await DioClient.dio.get('/diseases');
    return PriceList.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> create(String name, int price, {bool bhytCovered = true}) async {
    await DioClient.dio
        .post('/diseases', data: {'name': name, 'price': price, 'bhytCovered': bhytCovered});
  }

  Future<void> update(int id, {String? name, int? price, bool? active, bool? bhytCovered}) async {
    await DioClient.dio.patch('/diseases/$id', data: {
      'name': ?name,
      'price': ?price,
      'active': ?active,
      'bhytCovered': ?bhytCovered,
    });
  }
}
