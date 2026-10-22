class Doctor {
  final int id;
  final String name;
  final String? avatar; // server path, e.g. /uploads/avatars/x.jpg

  Doctor({required this.id, required this.name, this.avatar});

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        avatar: json['avatar'] as String?,
      );
}
