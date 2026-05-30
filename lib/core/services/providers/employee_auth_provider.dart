import 'package:flutter/material.dart';
import 'package:pro_dine/data/repositories/auth_repository.dart';
import 'package:pro_dine/data/models/employee_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStep {
  login,
  signupForm,
  verified,
}

class EmployeeAuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // Auth state
  User? _currentUser;
  EmployeeProfile? _employeeProfile;
  bool _isLoading = false;
  String? _errorMessage;
  AuthStep _currentStep = AuthStep.login;

  // Signup form state
  String? _signupEmployeeId;
  String? _signupFullName;
  String? _signupMobileNumber;
  String? _signupEmail;
  String? _signupPassword;

  // Phone verification state
  String? _verificationPhoneNumber;
  String? _verificationOTP;
  int _resendCountdown = 0;

  // Getters
  User? get currentUser => _currentUser;
  EmployeeProfile? get employeeProfile => _employeeProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthStep get currentStep => _currentStep;
  bool get isAuthenticated => _currentUser != null;
  String? get verificationPhoneNumber => _verificationPhoneNumber;
  int get resendCountdown => _resendCountdown;

  EmployeeAuthProvider() {
    _initializeUser();
  }

  void _initializeUser() {
    _currentUser = _authRepository.getCurrentUser();
    if (_currentUser != null) {
      _loadEmployeeProfile();
    }
    notifyListeners();
  }

  void _clearErrors() {
    _errorMessage = null;
  }

  // ========== LOGIN ==========

  Future<void> loginEmployee({
    String? email,
    String? mobileNumber,
    required String password,
  }) async {
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      final response = mobileNumber == null
          ? await _authRepository.signIn(
              email: email!,
              password: password,
            )
          : await _authRepository.signInWithPhone(
              phone: mobileNumber,
              password: password,
            );
      _currentUser = response.user;
      await _loadEmployeeProfile();
      _currentStep = AuthStep.verified;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== SIGNUP FORM ==========

  void startSignupFlow() {
    _currentStep = AuthStep.signupForm;
    _clearErrors();
    _clearSignupForm();
    notifyListeners();
  }

  void _clearSignupForm() {
    _signupEmployeeId = null;
    _signupFullName = null;
    _signupMobileNumber = null;
    _signupEmail = null;
    _signupPassword = null;
    _errorMessage = null;
  }

  Future<void> createEmployeeAccount({
    required String employeeId,
    required String fullName,
    required String mobileNumber,
    String? email,
    required String password,
    bool termsAccepted = true,
  }) async {
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      // Validation
      if (employeeId.isEmpty) throw Exception('Employee ID is required');
      if (fullName.isEmpty) throw Exception('Full Name is required');
      if (mobileNumber.isEmpty) throw Exception('Mobile Number is required');
      if (password.isEmpty) throw Exception('Password is required');
      if (!termsAccepted) throw Exception('Please agree to the terms');

      if (mobileNumber.length < 10) {
        throw Exception('Mobile Number must be at least 10 digits');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Check if employee ID already exists
      final idExists = await _authRepository.isEmployeeIdExists(employeeId);
      if (idExists) throw Exception('Employee ID already registered');

      // Check if phone number already exists
      final phoneExists =
          await _authRepository.isPhoneNumberExists(mobileNumber);
      if (phoneExists) throw Exception('Phone number already registered');

      // Create account
      final request = EmployeeSignupRequest(
        employeeId: employeeId,
        fullName: fullName,
        mobileNumber: mobileNumber,
        email: email,
        password: password,
        termsAccepted: termsAccepted,
      );

      final profile = await _authRepository.signUpEmployee(request: request);

      _currentUser = _authRepository.getCurrentUser();
      _employeeProfile = profile;

      _currentStep = AuthStep.login;
      _errorMessage = 'Account created successfully! Please login.';

      notifyListeners();
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== PHONE VERIFICATION ==========

  Future<void> verifyPhoneWithOTP(String otpCode) async {
    if (_verificationPhoneNumber == null) {
      _errorMessage = 'Phone number not found';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      if (otpCode.isEmpty) throw Exception('Please enter OTP');
      if (otpCode.length != 6) throw Exception('OTP must be 6 digits');

      final isVerified = await _authRepository.verifyEmployeePhone(
        phoneNumber: _verificationPhoneNumber!,
        otpCode: otpCode,
      );

      if (isVerified) {
        await _loadEmployeeProfile();
        _currentStep = AuthStep.verified;
        notifyListeners();
      } else {
        throw Exception('Invalid OTP');
      }
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendOTP() async {
    if (_verificationPhoneNumber == null) {
      _errorMessage = 'Phone number not found';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      await _authRepository.resendOTP(_verificationPhoneNumber!);
      _startResendCountdown();
      _errorMessage = 'OTP resent successfully';
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    Future.delayed(const Duration(seconds: 1), () {
      if (_resendCountdown > 0) {
        _resendCountdown--;
        notifyListeners();
        _startResendCountdown();
      }
    });
  }

  // ========== UTILITIES ==========

  Future<void> _loadEmployeeProfile() async {
    try {
      if (_currentUser == null) return;
      _employeeProfile =
          await _authRepository.getEmployeeProfile(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      print('Load employee profile error: $e');
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _employeeProfile = null;
      _currentStep = AuthStep.login;
      _clearSignupForm();
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void goBackToLogin() {
    _currentStep = AuthStep.login;
    _clearSignupForm();
    _clearErrors();
    notifyListeners();
  }

  String _parseError(String error) {
    if (error.contains('User already registered')) {
      return 'Email already registered. Please login or use a different email.';
    } else if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('Invalid OTP')) {
      return 'The OTP you entered is incorrect or expired';
    } else if (error.contains('User not found')) {
      return 'User account not found';
    }
    return error;
  }
}
