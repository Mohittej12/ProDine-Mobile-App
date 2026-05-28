class SupabaseConfig {
  // Hardcoded credentials for web development
  // In production, use environment variables or secure backend
  static const String supabaseUrl = 'https://pengkefnsyvpoaxtqedd.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_OOVzTiYDAh6fCMjHyA36aQ_ONsXp8Zt';

  static Future<void> initialize() async {
    // For web development, credentials are hardcoded above
    // For native (Android/iOS), you can use dotenv if needed
    print('✅ Supabase config loaded (web mode)');
  }

  static bool validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase configuration is missing');
    }
    return true;
  }
}
