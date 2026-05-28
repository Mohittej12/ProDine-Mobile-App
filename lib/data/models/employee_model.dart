class EmployeeSignupRequest {
  final String employeeId;
  final String fullName;
  final String mobileNumber;
  final String email;
  final String password;

  EmployeeSignupRequest({
    required this.employeeId,
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'email': email,
      'password': password,
    };
  }
}

class EmployeeProfile {
  final String id;
  final String userId;
  final String employeeId;
  final String fullName;
  final String mobileNumber;
  final String email;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeProfile({
    required this.id,
    required this.userId,
    required this.employeeId,
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.isPhoneVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      employeeId: json['employee_id'] as String,
      fullName: json['full_name'] as String,
      mobileNumber: json['mobile_number'] as String,
      email: json['email'] as String,
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'employee_id': employeeId,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'email': email,
      'is_phone_verified': isPhoneVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PhoneVerificationRequest {
  final String userId;
  final String mobileNumber;
  final String? otp;

  PhoneVerificationRequest({
    required this.userId,
    required this.mobileNumber,
    this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'mobile_number': mobileNumber,
      'otp': otp,
    };
  }
}
