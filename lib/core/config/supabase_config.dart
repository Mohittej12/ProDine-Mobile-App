import 'package:flutter/services.dart';

class SupabaseConfig {
  static String supabaseUrl = '';
  static String supabaseAnonKey = '';

  static Future<void> initialize() async {
    final env = await _loadEnv();
    supabaseUrl = env['SUPABASE_URL'] ?? '';
    supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? '';
    print('Supabase config loaded from .env');
  }

  static bool validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase configuration is missing');
    }
    return true;
  }

  static Future<Map<String, String>> _loadEnv() async {
    final content = await rootBundle.loadString('.env');
    final values = <String, String>{};

    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) continue;

      final key = line.substring(0, separatorIndex).trim();
      var value = line.substring(separatorIndex + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      values[key] = value;
    }

    return values;
  }
}
