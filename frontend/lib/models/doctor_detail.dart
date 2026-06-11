class DoctorDetail {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String address;
  final String email;

  DoctorDetail({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.address,
    required this.email,
  });

  factory DoctorDetail.fromJson(Map<String, dynamic> json) => DoctorDetail(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        age: (json['age'] as num?)?.toInt() ?? 0,
        gender: (json['gender'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        address: (json['address'] ?? '') as String,
        email: (json['email'] ?? '') as String,
      );
}
