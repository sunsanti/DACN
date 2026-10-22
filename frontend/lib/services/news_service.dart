import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/dio_client.dart';
import '../models/news.dart';
import 'auth_service.dart' show imagePart;

class NewsService {
  /// Newest first.
  Future<List<News>> list({int? limit}) async {
    final res = await DioClient.dio
        .get('/news', queryParameters: {'limit': ?limit});
    return (res.data as List)
        .map((e) => News.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Admin: title + link + cover image (multipart).
  Future<void> create(String title, String url, XFile image) async {
    await DioClient.dio.post('/news', data: FormData.fromMap({
      'title': title,
      'url': url,
      'image': await imagePart(image),
    }));
  }

  Future<void> delete(int id) async {
    await DioClient.dio.delete('/news/$id');
  }
}
