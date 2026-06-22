class Student {
  final String id;
  final String name;
  final String? parentPhone;
  final String? email;
  final String level;
  final String? section;
  final String gender;
  final String status;
  final String? classId;
  final double? paidAmount;

  Student({
    required this.id,
    required this.name,
    this.parentPhone,
    this.email,
    required this.level,
    this.section,
    required this.gender,
    required this.status,
    this.classId,
    this.paidAmount,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      parentPhone: json['parent_phone'],
      email: json['email'],
      level: json['level'],
      section: json['section'],
      gender: json['gender'],
      status: json['status'],
      classId: json['class_id'],
      paidAmount: json['paid_amount']?.toDouble(),
    );
  }
}