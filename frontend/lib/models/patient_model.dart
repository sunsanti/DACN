enum Gender { male, female }

class Patient {
  final int id;
  final String name;
  final Gender gender;
  final int age;
  final DateTime birthDate;
  final String email;
  final String phone;
  final String address;
  final String avatar;
  // Thêm theo yêu cầu của Quý
  final String cccd;
  final String bhyt;
  final DateTime? bhytExpiry;

  Patient({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.birthDate,
    required this.email,
    required this.phone,
    required this.address,
    required this.avatar,
    required this.cccd,
    required this.bhyt,
    this.bhytExpiry,
  });

  // Hàm chuyển từ JSON (Backend) sang Object (Flutter)
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      gender: json['gender'] == 'male' ? Gender.male : Gender.female,
      age: json['age'],
      birthDate: DateTime.parse(json['birthDate']),
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      avatar: json['avatar'],
      cccd: json['cccd'] ?? '', // Phòng hờ backend chưa có
      bhyt: json['bhyt'] ?? '',
      bhytExpiry: json['bhytExpiry'] != null
          ? DateTime.parse(json['bhytExpiry'])
          : null,
    );
  }
}
