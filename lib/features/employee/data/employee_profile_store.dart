import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeProfileData {
  const EmployeeProfileData({
    required this.name,
    required this.phone,
    required this.employeeId,
  });

  final String name;
  final String phone;
  final String employeeId;

  EmployeeProfileData copyWith({
    String? name,
    String? phone,
    String? employeeId,
  }) {
    return EmployeeProfileData(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      employeeId: employeeId ?? this.employeeId,
    );
  }
}

class EmployeeProfileStore extends ValueNotifier<EmployeeProfileData> {
  EmployeeProfileStore._()
    : super(
        const EmployeeProfileData(
          name: 'Sarah',
          phone: '+91 98765 43210',
          employeeId: 'PD-2048',
        ),
      );

  static final EmployeeProfileStore instance = EmployeeProfileStore._();
  static const String _passwordKey = 'employee_profile_password';
  static const String _defaultPassword = 'password123';

  void update(EmployeeProfileData profile) {
    value = profile;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(_passwordKey) ?? _defaultPassword;

    if (currentPassword != savedPassword) return false;

    await prefs.setString(_passwordKey, newPassword);
    return true;
  }
}
