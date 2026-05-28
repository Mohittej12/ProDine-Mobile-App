import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  late SupabaseClient _client;

  SupabaseClient get client => _client;

  Future<void> initialize(String url, String anonKey) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      _client = Supabase.instance.client;
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      rethrow;
    }
  }

  // Auth Methods
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      return await _client.auth.signUp(email: email, password: password);
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // Database Methods - Example for fetching data
  Future<List<Map<String, dynamic>>> fetchFromTable(String tableName) async {
    try {
      final response = await _client.from(tableName).select();
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Fetch error: $e');
      rethrow;
    }
  }

  // Insert data
  Future<Map<String, dynamic>> insertData(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    try {
      print('🔍 Attempting to insert into table: $tableName');
      print('📤 Data to insert: $data');
      
      // Check if client is initialized
      if (_client == null) {
        throw Exception('Supabase client is not initialized!');
      }
      
      print('✅ Supabase client is initialized');
      
      final response = await _client
          .from(tableName)
          .insert(data)
          .select()
          .single();
      
      print('✅ Data inserted successfully!');
      print('📥 Response: $response');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Insert error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Update data
  Future<void> updateData(
    String tableName,
    Map<String, dynamic> data,
    String columnName,
    dynamic value,
  ) async {
    try {
      await _client.from(tableName).update(data).eq(columnName, value);
    } catch (e) {
      print('Update error: $e');
      rethrow;
    }
  }

  // Delete data
  Future<void> deleteData(
    String tableName,
    String columnName,
    dynamic value,
  ) async {
    try {
      await _client.from(tableName).delete().eq(columnName, value);
    } catch (e) {
      print('Delete error: $e');
      rethrow;
    }
  }

  // Real-time subscription
  RealtimeChannel subscribeToTable(
    String tableName,
    Function(dynamic) onDataChange,
  ) {
    return _client
        .channel('public:$tableName')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) {
            onDataChange(payload);
          },
        )
        .subscribe();
  }
}
