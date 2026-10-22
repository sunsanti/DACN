class News {
  final int id;
  final String title;
  final String url;
  final String imagePath; // server path, e.g. /uploads/news/x.jpg
  final DateTime createdAt;

  News({
    required this.id,
    required this.title,
    required this.url,
    required this.imagePath,
    required this.createdAt,
  });

  factory News.fromJson(Map<String, dynamic> json) => News(
        id: json['id'] as int,
        title: (json['title'] ?? '') as String,
        url: (json['url'] ?? '') as String,
        imagePath: (json['imagePath'] ?? '') as String,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );
}
