class Patient {
  final int id;
  final String name;
  final String gender;
  final int age;
  final String email;
  final String? avatar;
  final String? cccd; // only present on /patient/me (owner)
  final Insurance? insurance; // BHYT found by CCCD; null → app hides the field
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
    this.avatar,
    this.cccd,
    this.insurance,
  });

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        gender: (json['gender'] ?? '') as String,
        age: (json['age'] as num?)?.toInt() ?? 0,
        email: (json['email'] ?? '') as String,
        avatar: json['avatar'] as String?,
        cccd: json['cccd'] as String?,
        insurance: json['insurance'] is Map
            ? Insurance.fromJson(Map<String, dynamic>.from(json['insurance']))
            : null,
        phone: (json['phone'] ?? '') as String,
        address: (json['address'] ?? '') as String,
      );
}

/// BHYT card looked up by CCCD in the registry (read-only for the patient).
class Insurance {
  final String cardNumber;
  final String validFrom; // yyyy-MM-dd
  final String validTo;
  final double rate; // 0.8 / 0.95 / 1
  final String status; // valid | expired | not_yet_valid

  Insurance({
    required this.cardNumber,
    required this.validFrom,
    required this.validTo,
    required this.rate,
    required this.status,
  });

  factory Insurance.fromJson(Map<String, dynamic> json) => Insurance(
        cardNumber: (json['cardNumber'] ?? '') as String,
        validFrom: (json['validFrom'] ?? '') as String,
        validTo: (json['validTo'] ?? '') as String,
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
        status: (json['status'] ?? 'valid') as String,
      );
}
