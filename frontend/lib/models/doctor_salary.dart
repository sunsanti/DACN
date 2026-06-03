class DoctorSalary {
  final int doctorId;
  final String name;
  final double totalHours;
  final int hourlyRate;
  final int salary;

  DoctorSalary({
    required this.doctorId,
    required this.name,
    required this.totalHours,
    required this.hourlyRate,
    required this.salary,
  });

  factory DoctorSalary.fromJson(Map<String, dynamic> json) => DoctorSalary(
        doctorId: json['doctorId'] as int,
        name: (json['name'] ?? '') as String,
        totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0,
        hourlyRate: (json['hourlyRate'] as num?)?.toInt() ?? 0,
        salary: (json['salary'] as num?)?.toInt() ?? 0,
      );
}
