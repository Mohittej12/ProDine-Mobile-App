import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_dine/core/services/supabase_service.dart';
import 'package:pro_dine/core/services/phone_verification_service.dart';
import 'package:pro_dine/data/models/employee_model.dart';

class AuthRepository {
  final _supabaseService = SupabaseService();
  final _phoneVerificationService = PhoneVerificationService();

  // ========== Basic Auth ==========

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabaseService.signUp(email, password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabaseService.signIn(email, password);
  }

  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    return await _supabaseService.signIn(
      _authEmailForPhone(phone),
      password,
    );
  }

  Future<void> signOut() async {
    return await _supabaseService.signOut();
  }

  User? getCurrentUser() {
    return _supabaseService.getCurrentUser();
  }

  bool isUserAuthenticated() {
    return _supabaseService.getCurrentUser() != null;
  }

  String? getUserEmail() {
    return _supabaseService.getCurrentUser()?.email;
  }

  // ========== Employee Signup Flow ==========

  Future<EmployeeProfile> signUpEmployee({
    required EmployeeSignupRequest request,
  }) async {
    try {
      final normalizedPhone = _toInternationalPhone(request.mobileNumber);

      print('Starting employee signup for: ${request.employeeId}');

      if (request.email != null) {
        final emailExists = await isEmployeeEmailExists(request.email!);
        if (emailExists) throw Exception('Email already registered');
      }

      final authEmail = request.email ?? _authEmailForPhone(normalizedPhone);

      final authResponse = request.email == null
          ? await _supabaseService.signUp(
              authEmail,
              request.password,
            )
          : await _supabaseService.signUp(
              request.email!,
              request.password,
            );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('Failed to create user account');
      }

      final profileResponse = await _supabaseService.client
          .rpc(
            'create_employee_profile',
            params: {
              'p_user_id': user.id,
              'p_employee_id': request.employeeId,
              'p_full_name': request.fullName,
              'p_mobile_number': normalizedPhone,
              'p_email': request.email?.toLowerCase(),
              'p_terms_accepted': request.termsAccepted,
            },
          )
          .select()
          .single();

      return EmployeeProfile.fromJson(profileResponse);
    } catch (e) {
      print('Employee signup error: $e');
      rethrow;
    }
  }

  Future<bool> verifyEmployeePhone({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final isValid = await _phoneVerificationService.verifyOTP(
        phoneNumber,
        otpCode,
      );

      if (isValid) {
        await _supabaseService.updateData(
          'employee_profiles',
          {'is_phone_verified': true},
          'mobile_number',
          _toInternationalPhone(phoneNumber),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Phone verification error: $e');
      rethrow;
    }
  }

  Future<EmployeeProfile?> getEmployeeProfile(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('employee_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return EmployeeProfile.fromJson(response);
    } catch (e) {
      print('Get employee profile error: $e');
      rethrow;
    }
  }

  Future<void> resendOTP(String phoneNumber) async {
    try {
      await _phoneVerificationService.resendOTP(phoneNumber);
    } catch (e) {
      print('Resend OTP error: $e');
      rethrow;
    }
  }

  Future<bool> isPhoneNumberExists(String phoneNumber) async {
    try {
      final response = await _supabaseService.client.rpc(
        'employee_profile_exists',
        params: {
          'p_employee_id': null,
          'p_mobile_number': _toInternationalPhone(phoneNumber),
          'p_email': null,
        },
      );

      return response == true;
    } catch (e) {
      print('Check phone error: $e');
      return false;
    }
  }

  Future<bool> isEmployeeIdExists(String employeeId) async {
    try {
      final response = await _supabaseService.client.rpc(
        'employee_profile_exists',
        params: {
          'p_employee_id': employeeId,
          'p_mobile_number': null,
          'p_email': null,
        },
      );

      return response == true;
    } catch (e) {
      print('Check employee ID error: $e');
      return false;
    }
  }

  Future<bool> isEmployeeEmailExists(String email) async {
    try {
      final response = await _supabaseService.client.rpc(
        'employee_profile_exists',
        params: {
          'p_employee_id': null,
          'p_mobile_number': null,
          'p_email': email.toLowerCase(),
        },
      );

      return response == true;
    } catch (e) {
      print('Check email error: $e');
      return false;
    }
  }

  String _toInternationalPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('+')) {
      return '+${trimmed.replaceAll(RegExp(r'[^0-9]'), '')}';
    }

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return '+91$digits';
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    return '+$digits';
  }

  String _authEmailForPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return 'employee_$digits@prodine.local';
  }
}
