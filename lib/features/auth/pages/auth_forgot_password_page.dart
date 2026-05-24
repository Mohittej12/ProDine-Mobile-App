import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_colors.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/core/widgets/app_button.dart';
import 'package:pro_dine/core/widgets/app_text_field.dart';
import 'package:pro_dine/features/auth/widgets/auth_scaffold.dart';

class AuthForgotPasswordPage extends StatefulWidget {
  const AuthForgotPasswordPage({super.key});

  @override
  State<AuthForgotPasswordPage> createState() => _AuthForgotPasswordPageState();
}

class _AuthForgotPasswordPageState extends State<AuthForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());

  bool _otpSent = false;
  bool _otpVerified = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  late int _secondsRemaining;
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = 30;
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _mobileController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _expiryText {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  void _sendOtp() {
    if (_mobileController.text.trim().isEmpty) {
      _showSnack('Please enter your mobile number');
      return;
    }

    final digits = _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) {
      _showSnack('Mobile number must be exactly 10 digits');
      return;
    }

    setState(() {
      _otpSent = true;
      _otpVerified = false;
      _secondsRemaining = 30;
      for (var controller in _otpControllers) {
        controller.clear();
      }
    });
    _startExpiryTimer();
    _showSnack(
        'OTP sent to +91 ${digits.substring(0, 5)} ${digits.substring(5)}');
    _otpFocusNodes.first.requestFocus();
  }

  void _verifyOtp() {
    if (_otpControllers.any((controller) => controller.text.trim().isEmpty)) {
      _showSnack('Enter the full 6-digit code');
      return;
    }

    setState(() {
      _otpVerified = true;
    });
  }

  void _resetPassword() {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match');
      return;
    }

    _showSnack('Password updated successfully');
    Future.delayed(const Duration(milliseconds: 700), () {
      context.go(AppRoutes.login);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      gradient: AppColors.forgotPasswordGradient,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'ProDine',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Forgot Password?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _otpSent && !_otpVerified
                    ? 'Enter the 6-digit OTP sent to your mobile number.'
                    : _otpVerified
                        ? 'Set your new password and confirm it to sign in.'
                        : 'Enter your mobile number to receive an OTP.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (!_otpSent) ...[
              AppTextField(
                controller: _mobileController,
                hint: 'Mobile Number',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_android_rounded),
              ),
              const SizedBox(height: 40),
              AppButton(
                text: 'Send OTP',
                onPressed: _sendOtp,
              ),
            ] else if (!_otpVerified) ...[
              Text(
                '+91 ${_mobileController.text.replaceAll(RegExp(r'[^0-9]'), '').padRight(10, '0').substring(0, 10)}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 48,
                    height: 56,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        fillColor: const Color(0xFFF9F9F9),
                        filled: true,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFEBEBEB),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primaryRed,
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (value) {
                        if (value.length == 1 && index < 5) {
                          _otpFocusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _otpFocusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Code expires in ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _expiryText,
                    style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _secondsRemaining <= 0 ? _sendOtp : null,
                child: Text(
                  _secondsRemaining <= 0 ? 'Resend Code' : 'Resend Code',
                  style: TextStyle(
                    color: _secondsRemaining <= 0
                        ? AppColors.primaryRed
                        : AppColors.primaryRed.withOpacity(0.5),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Verify OTP',
                onPressed: _verifyOtp,
              ),
            ] else ...[
              AppTextField(
                controller: _newPasswordController,
                hint: 'New Password',
                obscureText: _obscureNewPassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(
                    () => _obscureNewPassword = !_obscureNewPassword,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Password must include at least one uppercase letter';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return 'Password must include at least one lowercase letter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmPasswordController,
                hint: 'Confirm New Password',
                obscureText: _obscureConfirmPassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Reset Password & Sign In',
                onPressed: _resetPassword,
              ),
            ],
            const SizedBox(height: 32),

            // Institutional Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Remember your password?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
