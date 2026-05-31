import 'package:flutter/foundation.dart';
import 'package:pro_dine/data/repositories/auth_repository.dart';

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
  final AuthRepository _authRepository = AuthRepository();

  void update(EmployeeProfileData profile) {
    value = profile;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      return await _authRepository.changeEmployeePassword(
        mobileNumber: value.phone,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      if (e.toString().contains('Invalid login credentials') ||
          e.toString().contains('Invalid credentials')) {
        return false;
      }
      rethrow;
    }
  }
}
