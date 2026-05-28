# Employee Authentication Integration Guide

## ✅ Setup Completed

A complete employee authentication system has been implemented with the following features:

### Components Created:
1. ✅ **Data Models** - `lib/data/models/employee_model.dart`
2. ✅ **Phone Verification Service** - `lib/core/services/phone_verification_service.dart`
3. ✅ **Updated Auth Repository** - `lib/data/repositories/auth_repository.dart`
4. ✅ **Employee Auth Provider** - `lib/core/services/providers/employee_auth_provider.dart`
5. ✅ **Login Screen** - `lib/features/employee/screens/employee_login_screen.dart`
6. ✅ **Signup Screen** - `lib/features/employee/screens/employee_signup_screen.dart`
7. ✅ **Phone Verification Screen** - `lib/features/employee/screens/phone_verification_screen.dart`
8. ✅ **Database Schema SQL** - `EMPLOYEE_AUTH_DATABASE_SCHEMA.sql`
9. ✅ **Updated app.dart** - Added providers to MultiProvider

---

## 📋 Step-by-Step Implementation

### **STEP 1: Create Database Tables**

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Copy all SQL from `EMPLOYEE_AUTH_DATABASE_SCHEMA.sql`
4. Paste and run the queries

This will create:
- `employee_profiles` table - Stores employee information
- `verification_codes` table - Stores OTP codes for phone verification

### **STEP 2: Update Your Routing** 

Add this to your `app_router.dart` to navigate to employee login:

```dart
import 'package:go_router/go_router.dart';
import 'package:pro_dine/features/employee/screens/employee_login_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/employee-login',
      name: 'employee-login',
      builder: (context, state) => const EmployeeLoginScreen(),
    ),
    // ... other routes
  ],
);
```

### **STEP 3: Add Employee Login Entry Point**

In your main app or home screen, add a button to navigate to employee login:

```dart
ElevatedButton(
  onPressed: () {
    context.pushNamed('employee-login');
  },
  child: const Text('Employee Login'),
)
```

---

## 🔄 Authentication Flow

### **Flow 1: Login (Existing Employee)**
```
Login Screen (Email + Password)
    ↓
Validate credentials
    ↓
Get employee profile
    ↓
Dashboard (Home)
```

### **Flow 2: Create Account (New Employee)**
```
Login Screen
    ↓ (Click "Create Account")
Signup Screen (Employee ID, Full Name, Phone, Email, Password)
    ↓ (Validate all fields)
Create Supabase auth user
    ↓
Store employee profile in DB
    ↓
Send OTP to phone number
    ↓
Phone Verification Screen (Enter 6-digit OTP)
    ↓ (OTP verified)
Dashboard (Home)
    ↓ (Redirect to login on app restart)
```

---

## 📱 Signup Screen Fields

When users click "Create Account":

1. **Employee ID** (Required)
   - Minimum 3 characters
   - Must be unique
   - Example: EMP001

2. **Full Name** (Required)
   - Must include first and last name
   - Example: John Doe

3. **Mobile Number** (Required)
   - Minimum 10 digits
   - Can include country code
   - Example: +91 9876543210

4. **Email Address** (Required)
   - Must be valid email format
   - Example: john@prodine.com

5. **Password** (Required)
   - Minimum 6 characters
   - Should include mix of letters/numbers for security

6. **Confirm Password** (Required)
   - Must match password field

7. **Terms & Conditions** (Required)
   - Checkbox to agree

---

## 📞 Phone Verification Flow

After signup:

1. **OTP Sent**: 6-digit code sent to phone number (currently logged in console)
2. **Enter OTP**: User enters 6 digits in individual input fields
3. **Verification**: 
   - If correct → Profile marked as verified → Dashboard
   - If incorrect → Error message
   - If expired → Can resend after 60 seconds

### **OTP Details**:
- **Length**: 6 digits
- **Validity**: 10 minutes
- **Resend Cooldown**: 60 seconds
- **Attempts**: No limit (for MVP, can add limit later)

---

## 💾 Database Schema

### **employee_profiles table**:
```
- id (UUID) - Primary key
- user_id (UUID) - Reference to auth.users
- employee_id (VARCHAR) - Unique employee identifier
- full_name (VARCHAR) - Employee's full name
- mobile_number (VARCHAR) - Phone number
- email (VARCHAR) - Email address
- is_phone_verified (BOOLEAN) - Verification status
- user_type (VARCHAR) - Role (default: 'employee')
- created_at (TIMESTAMP) - Account creation time
- updated_at (TIMESTAMP) - Last update time
```

### **verification_codes table**:
```
- id (UUID) - Primary key
- phone_number (VARCHAR) - Phone to verify
- otp (VARCHAR) - 6-digit code
- is_verified (BOOLEAN) - Verification status
- attempts (INT) - Failed attempts count
- expires_at (TIMESTAMP) - OTP expiration time
- created_at (TIMESTAMP) - Creation time
```

---

## 🔐 Security Features Implemented

✅ **Password Security**
- Minimum 6 characters required
- Hashed by Supabase Auth
- Password confirmation on signup

✅ **Phone Verification**
- OTP-based verification
- Time-limited codes (10 minutes)
- Resend cooldown (60 seconds)

✅ **Data Validation**
- Email format validation
- Phone number validation
- Unique constraints on email, phone, employee ID

✅ **Row Level Security (RLS)**
- Users can only access their own profile
- Cannot see other employees' data
- Verification codes not directly accessible

✅ **Duplicate Prevention**
- Employee ID uniqueness check
- Phone number uniqueness check
- Email uniqueness (handled by Supabase Auth)

---

## 🚀 Usage Example

### **In Your Feature Screens**:

```dart
import 'package:provider/provider.dart';
import 'package:pro_dine/core/services/providers/employee_auth_provider.dart';

class MyEmployeeFeature extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeAuthProvider>(
      builder: (context, authProvider, _) {
        // Check if employee is authenticated
        if (!authProvider.isAuthenticated) {
          return const EmployeeLoginScreen();
        }

        // Get employee info
        final profile = authProvider.employeeProfile;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Welcome ${profile?.fullName}'),
          ),
          body: Column(
            children: [
              Text('Employee ID: ${profile?.employeeId}'),
              Text('Email: ${profile?.email}'),
              Text('Phone: ${profile?.mobileNumber}'),
              Text('Verified: ${profile?.isPhoneVerified ? "Yes" : "No"}'),
              ElevatedButton(
                onPressed: () => authProvider.signOut(),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 🧪 Testing the System

### **Test Signup Flow**:
1. Click "Create Account"
2. Enter test data:
   - Employee ID: `TEST001`
   - Full Name: `Test User`
   - Mobile: `9999999999`
   - Email: `test@prodine.com`
   - Password: `Test@123`
3. Click "Create Account"
4. Check console for OTP (development mode)
5. Enter OTP in verification screen
6. Should redirect to Dashboard

### **Test Login Flow**:
1. Enter email and password used in signup
2. Should redirect to Dashboard with employee info

### **Test Resend OTP**:
1. On verification screen, click "Resend Code" button
2. Should wait 60 seconds before showing button again

---

## 📝 TODO for Production

- [ ] Integrate real SMS provider (Twilio, AWS SNS, etc.)
- [ ] Add password reset flow
- [ ] Add remember me functionality
- [ ] Add two-factor authentication (2FA)
- [ ] Add employee verification by HR admin
- [ ] Add device fingerprinting
- [ ] Add login attempt limits and blocking
- [ ] Add audit logging
- [ ] Add email verification (optional)
- [ ] Add biometric login
- [ ] Add refresh token rotation

---

## 🐛 Troubleshooting

### Issue: "Employee ID already registered"
**Solution**: Use a unique employee ID that hasn't been used before

### Issue: "Phone number already registered"
**Solution**: Use a new phone number or update existing profile

### Issue: "Invalid OTP"
**Solution**: 
- Check that you entered the correct 6-digit code
- Code is valid for 10 minutes
- Check console for the OTP in development

### Issue: "Passwords do not match"
**Solution**: Ensure password and confirm password fields are identical

### Issue: OTP not showing in console
**Solution**: 
- OTP service uses console logging in development
- Replace with real SMS provider in production
- Check your IDE console, not browser console

---

## 📞 Integration with SMS Providers

When ready to send real SMS, update `phone_verification_service.dart`:

### **Twilio Example**:
```dart
Future<void> _sendSMSViaTwilio(String phoneNumber, String message) async {
  // Implement Twilio SDK call
  // await twilio.messages.create(
  //   from: twilioPhoneNumber,
  //   to: phoneNumber,
  //   body: message,
  // );
}
```

### **AWS SNS Example**:
```dart
Future<void> _sendSMSViaAWS(String phoneNumber, String message) async {
  // Implement AWS SNS call
}
```

---

## 📚 Related Files

- **Models**: `lib/data/models/employee_model.dart`
- **Services**: `lib/core/services/phone_verification_service.dart`
- **Repository**: `lib/data/repositories/auth_repository.dart`
- **Provider**: `lib/core/services/providers/employee_auth_provider.dart`
- **Screens**:
  - `lib/features/employee/screens/employee_login_screen.dart`
  - `lib/features/employee/screens/employee_signup_screen.dart`
  - `lib/features/employee/screens/phone_verification_screen.dart`
- **Database**: `EMPLOYEE_AUTH_DATABASE_SCHEMA.sql`

---

## ✨ What's Ready Now

✅ Complete employee signup flow
✅ Phone verification with OTP
✅ Employee login authentication
✅ Secure database storage
✅ State management with Provider
✅ Form validation
✅ Error handling
✅ Responsive UI screens

Your authentication system is ready to use!
