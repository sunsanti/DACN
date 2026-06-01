class Doctor {
  final int id;
  final String name;
  final int age;
  final DateTime dateOfBirth;
  final String phone;
  final String address;
  final String email;
  final String gender;

  Doctor({
    required this.id,
    required this.name,
    required this.age,
    required this.dateOfBirth,
    required this.phone,
    required this.address,
    required this.email,
    required this.gender,
  });

  // Hàm chuyển đổi từ JSON (NestJS) sang Object (Flutter)
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Chưa cập nhật',
      age: json['age'] ?? 0,
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : DateTime.now(),
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? 'male',
    );
  }

  // Hàm chuyển đổi ngược từ Object sang JSON (khi cần gửi dữ liệu lên)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'phone': phone,
      'address': address,
      'email': email,
      'gender': gender,
    };
  }
}