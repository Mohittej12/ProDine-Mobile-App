import 'package:pro_dine/core/services/supabase_service.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';

class EmployeeOrderRepository {
  final SupabaseService _supabaseService = SupabaseService();

  Future<EmployeeOrderEntry> createOrder(
    EmployeeOrderEntry order, {
    String? userId,
  }) async {
    final data = order.toJson();
    if (userId != null) {
      data['user_id'] = userId;
    }

    final response = await _supabaseService.insertData(
      'employee_orders',
      data,
    );

    return EmployeeOrderEntry.fromJson(response);
  }

  Future<List<EmployeeOrderEntry>> fetchOrdersByEmployee(
    String employeeId,
  ) async {
    final response = await _supabaseService.client
        .from('employee_orders')
        .select()
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false);

    if (response == null) {
      return [];
    }

    final rows = response as List<dynamic>;
    return rows
        .map((row) => EmployeeOrderEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
