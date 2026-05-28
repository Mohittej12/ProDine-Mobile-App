# Supabase Integration Guide for PrōDine

## ✅ Setup Completed

Your Flutter application is now ready to integrate with Supabase! Here's what has been set up:

### Installed Components:
1. ✅ **supabase_flutter** - Official Supabase Flutter SDK
2. ✅ **flutter_dotenv** - Environment variables management
3. ✅ **Supabase Configuration** - `lib/core/config/supabase_config.dart`
4. ✅ **Supabase Service** - `lib/core/services/supabase_service.dart`
5. ✅ **Auth Repository** - `lib/data/repositories/auth_repository.dart`
6. ✅ **Auth Provider** - `lib/core/services/providers/auth_provider.dart`
7. ✅ **Environment Configuration** - `.env` file with credentials

---

## 📋 Your Supabase Credentials (Already Configured)

```
Project URL: https://pengkefnsyvpoaxtqedd.supabase.co
Publishable API Key: sb_publishable_OOVzTiYDAh6fCMjHyA36aQ_ONsXp8Zt
```

---

## 🚀 Next Steps to Complete

### Step 1: Set Up Your Supabase Database Tables

Go to your Supabase Dashboard (https://app.supabase.com/) and create these tables:

#### **1. Users Table (for profile extension)**
```sql
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email VARCHAR(255) NOT NULL UNIQUE,
  user_type VARCHAR(50), -- 'admin', 'vendor', 'employee', 'customer'
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

#### **2. Vendors Table (if you need vendor management)**
```sql
CREATE TABLE public.vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id),
  business_name VARCHAR(255) NOT NULL,
  description TEXT,
  contact_phone VARCHAR(20),
  location VARCHAR(255),
  rating DECIMAL(3,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

#### **3. Products/Menu Items Table**
```sql
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES public.vendors(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  image_url VARCHAR(500),
  category VARCHAR(100),
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

#### **4. Orders Table**
```sql
CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id),
  vendor_id UUID NOT NULL REFERENCES public.vendors(id),
  total_amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'confirmed', 'preparing', 'ready', 'completed'
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

#### **5. Order Items Table**
```sql
CREATE TABLE public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id),
  product_id UUID NOT NULL REFERENCES public.products(id),
  quantity INT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);
```

### Step 2: Enable Row Level Security (RLS)

1. Go to **Authentication** > **Policies** in Supabase Dashboard
2. For each table, enable RLS and create policies:

**Example for users table:**
```sql
-- Allow users to see their own data
CREATE POLICY "Users can read their own data" ON public.users
  FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own data
CREATE POLICY "Users can update their own data" ON public.users
  FOR UPDATE USING (auth.uid() = id);
```

### Step 3: Update Your Auth Feature

Modify your existing auth feature to use the new AuthProvider:

```dart
// In your auth login screen
import 'package:provider/provider.dart';
import 'package:pro_dine/core/services/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Login')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 20),
                if (authProvider.errorMessage != null)
                  Text(
                    authProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () => _handleLogin(context, authProvider),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLogin(BuildContext context, AuthProvider authProvider) async {
    try {
      await authProvider.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Navigate to home screen
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('Login failed: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

### Step 4: Add Provider to Your App

Update your `main.dart` or `app.dart` to provide AuthProvider:

```dart
import 'package:provider/provider.dart';
import 'package:pro_dine/core/services/providers/auth_provider.dart';

// In your app widget
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    // Add other providers here
  ],
  child: MaterialApp(
    // Your app configuration
  ),
)
```

### Step 5: Create Data Repositories for Each Feature

Create repositories for vendors, products, orders, etc., following the same pattern as `auth_repository.dart`:

```dart
class VendorRepository {
  final _supabaseService = SupabaseService();

  Future<List<Map<String, dynamic>>> getAllVendors() async {
    return await _supabaseService.fetchFromTable('vendors');
  }

  Future<Map<String, dynamic>> getVendorById(String id) async {
    final response = await _supabaseService.client
        .from('vendors')
        .select()
        .eq('id', id)
        .single();
    return response as Map<String, dynamic>;
  }

  Future<void> createVendor(Map<String, dynamic> data) async {
    await _supabaseService.insertData('vendors', data);
  }
}
```

### Step 6: Handle Authentication State in Router

Update your `app_router.dart` to protect routes:

```dart
import 'package:pro_dine/core/services/supabase_service.dart';

final appRouter = GoRouter(
  redirect: (context, state) {
    final user = SupabaseService().getCurrentUser();
    
    // If no user and not on login/signup page, redirect to login
    if (user == null && state.fullPath != '/login' && state.fullPath != '/signup') {
      return '/login';
    }
    
    // If user exists and on login/signup, redirect to home
    if (user != null && (state.fullPath == '/login' || state.fullPath == '/signup')) {
      return '/home';
    }
    
    return null;
  },
  routes: [
    // Your routes here
  ],
);
```

---

## 🔐 Important Security Notes

1. **Never commit credentials to Git**: The `.env` file is already excluded from git (add to `.gitignore` if needed)
2. **Use RLS Policies**: Always set up Row Level Security policies to protect your data
3. **Validate on Backend**: Always validate user input and permissions server-side
4. **Keep API Keys Safe**: The anonymous key is public, but keep it only in published apps

---

## 📚 Useful Examples

### Fetch Data with Real-time Updates
```dart
final supabaseService = SupabaseService();

// Subscribe to real-time changes
supabaseService.subscribeToTable('products', (payload) {
  print('Data changed: $payload');
});
```

### Insert Data
```dart
final supabaseService = SupabaseService();

await supabaseService.insertData('products', {
  'vendor_id': vendorId,
  'name': 'Product Name',
  'price': 99.99,
});
```

### Update Data
```dart
await supabaseService.updateData(
  'products',
  {'price': 89.99},
  'id',
  productId,
);
```

### Delete Data
```dart
await supabaseService.deleteData('products', 'id', productId);
```

---

## 🐛 Troubleshooting

### Issue: "Supabase initialization failed"
- Check that `.env` file exists in the project root
- Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are correct
- Ensure `.env` is added to pubspec.yaml assets

### Issue: "Unauthorized" errors
- Check Row Level Security policies are set up correctly
- Verify user is logged in before making requests
- Check table permissions in Supabase dashboard

### Issue: "Package not found"
- Run `flutter pub get` again
- Clear Flutter cache: `flutter clean && flutter pub get`

---

## 📞 Resources

- **Supabase Docs**: https://supabase.com/docs
- **Supabase Flutter SDK**: https://supabase.com/docs/reference/dart/start
- **Supabase Real-time**: https://supabase.com/docs/guides/realtime
- **Auth Documentation**: https://supabase.com/docs/guides/auth

---

## ✨ What's Ready Now

Your project can now:
✅ Connect to Supabase backend
✅ Handle user authentication (sign up, login, logout)
✅ Manage user state with Provider
✅ Perform CRUD operations on any table
✅ Subscribe to real-time data changes
✅ Manage environment variables securely

Start building your features using the repository and provider pattern!
