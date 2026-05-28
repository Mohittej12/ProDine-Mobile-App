import 'package:pro_dine/core/services/supabase_service.dart';

class PhoneVerificationService {
  final _supabaseService = SupabaseService();

  /// Send OTP to phone number
  /// In production, integrate with Twilio, AWS SNS, or similar SMS provider
  Future<void> sendOTP(String phoneNumber) async {
    try {
      print('📱 Starting OTP generation for: $phoneNumber');
      
      // Store OTP in verification_codes table
      final otp = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      print('🔐 Generated OTP: $otp');
      print('⏰ Expires at: $expiresAt');

      final insertData = {
        'phone_number': phoneNumber,
        'otp': otp,
        'expires_at': expiresAt.toIso8601String(),
        'attempts': 0,
        'is_verified': false,
      };

      print('📤 Inserting into verification_codes table: $insertData');

      await _supabaseService.insertData('verification_codes', insertData);

      print('✅ OTP stored successfully in database');
      
      // Log OTP for development
      print('🔐 OTP for $phoneNumber: $otp (Expires in 10 minutes)');
    } catch (e) {
      print('❌ Send OTP error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Verify OTP code
  Future<bool> verifyOTP(String phoneNumber, String otpCode) async {
    try {
      print('🔍 Verifying OTP: $otpCode for phone: $phoneNumber');
      
      final response = await _supabaseService.client
          .from('verification_codes')
          .select()
          .eq('phone_number', phoneNumber)
          .eq('otp', otpCode)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print('❌ OTP not found or expired');
        throw Exception('Invalid or expired OTP');
      }

      print('✅ OTP verified successfully');

      // Mark as verified
      await _supabaseService.updateData(
        'verification_codes',
        {'is_verified': true},
        'phone_number',
        phoneNumber,
      );
      
      print('✅ OTP marked as verified in database');
      return true;
    } catch (e) {
      print('❌ Verify OTP error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Check if phone number is already verified
  Future<bool> isPhoneVerified(String phoneNumber) async {
    try {
      final response = await _supabaseService.client
          .from('verification_codes')
          .select()
          .eq('phone_number', phoneNumber)
          .eq('is_verified', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Check verification error: $e');
      return false;
    }
  }

  /// Resend OTP (with cooldown)
  Future<void> resendOTP(String phoneNumber) async {
    try {
      // Check last OTP sent time
      final lastOtp = await _supabaseService.client
          .from('verification_codes')
          .select()
          .eq('phone_number', phoneNumber)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (lastOtp != null) {
        final createdAt = DateTime.parse(lastOtp['created_at']);
        final secondsAgo = DateTime.now().difference(createdAt).inSeconds;

        if (secondsAgo < 60) {
          throw Exception('Please wait ${60 - secondsAgo} seconds before requesting a new OTP');
        }
      }

      await sendOTP(phoneNumber);
    } catch (e) {
      print('Resend OTP error: $e');
      rethrow;
    }
  }

  /// Generate random 6-digit OTP
  String _generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  // TODO: Implement SMS sending via Twilio or your provider
  // Future<void> _sendSMSViaTwilio(String phoneNumber, String message) async {
  //   // Implementation with Twilio SDK
  // }
}
