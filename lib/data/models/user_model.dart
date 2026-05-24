class UserModel {
  final String id;
  final String name;
  final String employeeId;
  final String program;
  final String costCode;
  final String department;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.program,
    required this.costCode,
    required this.department,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      employeeId: json['employeeId'],
      program: json['program'],
      costCode: json['costCode'],
      department: json['department'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeId': employeeId,
      'program': program,
      'costCode': costCode,
      'department': department,
      'role': role,
    };
  }
}