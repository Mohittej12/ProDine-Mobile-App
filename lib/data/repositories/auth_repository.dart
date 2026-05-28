import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_dine/core/services/supabase_service.dart';
import 'package:pro_dine/core/services/phone_verification_service.dart';
import 'package:pro_dine/data/models/employee_model.dart';

class AuthRepository {
  final _supabaseService = SupabaseService();
  final _phoneVerificationService = PhoneVerificationService();

  // ========== Basic Auth ==========

  // Sign up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabaseService.signUp(email, password);
  }

  // Sign in
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabaseService.signIn(email, password);
  }

  // Sign out
  Future<void> signOut() async {
    return await _supabaseService.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _supabaseService.getCurrentUser();
  }

  // Check if user is authenticated
  bool isUserAuthenticated() {
    return _supabaseService.getCurrentUser() != null;
  }

  // Get current user email
  String? getUserEmail() {
    return _supabaseService.getCurrentUser()?.email;
  }

  // ========== Employee Signup Flow ==========

  /// Step 1: Create employee account and auth user
  /// Skipping OTP verification for now - all fields saved directly to database
  Future<EmployeeProfile> signUpEmployee({
    required EmployeeSignupRequest request,
  }) async {
    try {
      print('👤 Starting employee signup for: ${request.email}');
      
      // Create Supabase auth user
      print('🔐 Creating Supabase auth user...');
      final authResponse = await _supabaseService.signUp(
        request.email,
        request.password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user account - user is null');
      }

      print('✅ Auth user created with ID: ${authResponse.user!.id}');

      // Store employee profile in database
      final employeeData = {
        'user_id': authResponse.user!.id,
        'employee_id': request.employeeId,
        'full_name': request.fullName,
        'mobile_number': request.mobileNumber,
        'email': request.email,
        'is_phone_verified': false,
        'user_type': 'employee',
      };

      print('💾 Storing employee profile in database: $employeeData');

      final response = await _supabaseService.insertData(
        'employee_profiles',
        employeeData,
      );

      print('✅ Employee profile stored successfully');
      print('✅ Account created! Phone verification skipped. Please login now.');
      
      return EmployeeProfile.fromJson(response);
    } catch (e) {
      print('❌ Employee signup error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Step 2: Verify phone number with OTP
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
        // Update employee profile to mark phone as verified
        await _supabaseService.updateData(
          'employee_profiles',
          {'is_phone_verified': true},
          'mobile_number',
          phoneNumber,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Phone verification error: $e');
      rethrow;
    }
  }

  /// Step 3: Get employee profile by user ID
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

  /// Resend OTP
  Future<void> resendOTP(String phoneNumber) async {
    try {
      await _phoneVerificationService.resendOTP(phoneNumber);
    } catch (e) {
      print('Resend OTP error: $e');
      rethrow;
    }
  }

  /// Check if phone number exists
  Future<bool> isPhoneNumberExists(String phoneNumber) async {
    try {
      final response = await _supabaseService.client
          .from('employee_profiles')
          .select()
          .eq('mobile_number', phoneNumber)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Check phone error: $e');
      return false;
    }
  }

  /// Check if employee ID exists
  Future<bool> isEmployeeIdExists(String employeeId) async {
    try {
      final response = await _supabaseService.client
          .from('employee_profiles')
          .select()
          .eq('employee_id', employeeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Check employee ID error: $e');
      return false;
    }
  }
}
