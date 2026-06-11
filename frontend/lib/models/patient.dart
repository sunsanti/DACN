class Patient {
  final int id;
  final String name;
  final String gender;
  final int age;
  final String email;
  final String phone;
  final String address;

  Patient({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        gender: (json['gender'] ?? '') as String,
        age: (json['age'] as num?)?.toInt() ?? 0,
        email: (json['email'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        address: (json['address'] ?? '') as String,
      );
}
