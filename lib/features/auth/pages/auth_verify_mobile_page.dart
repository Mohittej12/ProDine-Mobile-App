import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_colors.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/core/widgets/app_button.dart';
import 'package:pro_dine/features/auth/widgets/auth_scaffold.dart';

class AuthVerifyMobilePage extends StatefulWidget {
  final String? mobileNumber;

  const AuthVerifyMobilePage({super.key, this.mobileNumber});

  @override
  State<AuthVerifyMobilePage> createState() => _AuthVerifyMobilePageState();
}

class _AuthVerifyMobilePageState extends State<AuthVerifyMobilePage> {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  late int _secondsRemaining;
  Timer? _expiryTimer;
  bool? _verificationSuccess;

  String get _formattedMobileNumber {
    final digits = widget.mobileNumber?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    if (digits.isNotEmpty) {
      return '+91 $digits';
    }
    return '+91 98765 43210';
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _secondsRemaining = 30;
    _startExpiryTimer();
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() {
        _secondsRemaining -= 1;
      });
    });
  }

  String get _expiryText {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyCode() {
    if (_controllers.any((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the 6-digit verification code'),
        ),
      );
      return;
    }

    setState(() {
      _verificationSuccess = null;
    });

    Future.delayed(const Duration(milliseconds: 450), () {
      setState(() {
        _verificationSuccess = true;
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        context.go(AppRoutes.login);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      gradient: AppColors.loginGradient,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: const Color(0xFFF8F8F8),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.pop(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 23,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ProDine',
            style: TextStyle(
              color: AppColors.primaryRed,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Verify Mobile Number',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Text(
                'We\'ve sent a 6-digit code to',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formattedMobileNumber,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              6,
              (index) => SizedBox(
                width: 48,
                height: 56,
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
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
                  onChanged: (value) => _onOtpChanged(index, value),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
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
            onPressed: () {
              if (_secondsRemaining <= 0) {
                setState(() {
                  _secondsRemaining = 30;
                  _verificationSuccess = null;
                });
                _controllers.forEach((controller) => controller.clear());
                _startExpiryTimer();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('A new code has been sent.'),
                  ),
                );
              }
            },
            child: const Text(
              'Resend Code',
              style: TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Verify Mobile Number',
            onPressed: _verifyCode,
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _verificationSuccess == null
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(_verificationSuccess),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: _verificationSuccess == true
                          ? const Color(0xFFE7F7EE)
                          : const Color(0xFFFDECEC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _verificationSuccess == true
                            ? const Color(0xFF38A46B)
                            : const Color(0xFFDE3A3A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _verificationSuccess == true
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          color: _verificationSuccess == true
                              ? const Color(0xFF38A46B)
                              : const Color(0xFFDE3A3A),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _verificationSuccess == true
                              ? 'Code verified — redirecting to sign in.'
                              : 'Code verification failed. Try again.',
                          style: TextStyle(
                            color: _verificationSuccess == true
                                ? const Color(0xFF1F6D3C)
                                : const Color(0xFF801F1F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Institutional Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Wrong mobile number?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Change Number',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                _infoRow(
                  Icons.info_outline_rounded,
                  'Make sure your mobile number can receive OTP messages',
                ),
                const SizedBox(height: 12),
                _infoRow(
                  Icons.timer_outlined,
                  'The code is valid for 10 minutes',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
