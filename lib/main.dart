import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_dine/app.dart';
import 'package:pro_dine/core/config/supabase_config.dart';
import 'package:pro_dine/core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting PrōDine app initialization...');

  // Load environment variables
  print('📋 Loading Supabase configuration...');
  await SupabaseConfig.initialize();

  // Validate and initialize Supabase
  try {
    print('🔐 Validating Supabase config...');
    SupabaseConfig.validate();
    print('✅ Supabase config is valid');
    
    print('🌐 Initializing Supabase client...');
    await SupabaseService().initialize(
      SupabaseConfig.supabaseUrl,
      SupabaseConfig.supabaseAnonKey,
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
    print('⚠️  App will run but database operations will fail');
  }

  print('🎨 Setting system UI overlay...');
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFFFFFBF7),
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  print('🚀 Launching app...');
  runApp(const App());
}
