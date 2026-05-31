import 'package:flutter/foundation.dart';
import 'package:pro_dine/data/repositories/employee_order_repository.dart';

class EmployeeOrderItem {
  const EmployeeOrderItem({
    required this.name,
    required this.meal,
    required this.quantity,
    required this.price,
    required this.imagePath,
  });

  final String name;
  final String meal;
  final int quantity;
  final int price;
  final String imagePath;

  String get priceLabel => '₹$price';

  factory EmployeeOrderItem.fromJson(Map<String, dynamic> json) {
    return EmployeeOrderItem(
      name: json['name'] as String? ?? '',
      meal: json['meal'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      price: json['price'] as int? ?? 0,
      imagePath: json['imagePath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'meal': meal,
      'quantity': quantity,
      'price': price,
      'imagePath': imagePath,
    };
  }
}

class EmployeeOrderEntry {
  const EmployeeOrderEntry({
    required this.orderId,
    required this.employeeId,
    required this.userName,
    required this.shopId,
    required this.shopName,
    required this.orderIntent,
    required this.items,
    required this.amount,
    required this.status,
    required this.pickupSlot,
    required this.isTicketing,
    required this.createdAt,
  });

  final String orderId;
  final String employeeId;
  final String userName;
  final String shopId;
  final String shopName;
  final String orderIntent;
  final List<EmployeeOrderItem> items;
  final int amount;
  final String status;
  final String pickupSlot;
  final bool isTicketing;
  final DateTime createdAt;

  factory EmployeeOrderEntry.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final itemsList = <EmployeeOrderItem>[];

    if (itemsJson is List) {
      itemsList.addAll(
        itemsJson.map((item) {
          if (item is Map<String, dynamic>) {
            return EmployeeOrderItem.fromJson(item);
          }
          return EmployeeOrderItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }),
      );
    }

    return EmployeeOrderEntry(
      orderId: json['order_id'] as String? ?? json['orderId'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? json['employeeId'] as String? ?? '',
      userName: json['user_name'] as String? ?? json['userName'] as String? ?? '',
      shopId: json['shop_id'] as String? ?? json['shopId'] as String? ?? '',
      shopName: json['shop_name'] as String? ?? json['shopName'] as String? ?? '',
      orderIntent:
          json['order_intent'] as String? ?? json['orderIntent'] as String? ?? '',
      items: itemsList,
      amount: json['amount'] as int? ?? (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      pickupSlot: json['pickup_slot'] as String? ?? json['pickupSlot'] as String? ?? '',
      isTicketing:
          json['is_ticketing'] as bool? ?? json['isTicketing'] as bool? ?? false,
      createdAt: DateTime.tryParse(
            json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'employee_id': employeeId,
      'user_name': userName,
      'shop_id': shopId,
      'shop_name': shopName,
      'order_intent': orderIntent,
      'items': items.map((item) => item.toJson()).toList(),
      'amount': amount.toDouble(),
      'status': status,
      'pickup_slot': pickupSlot,
      'is_ticketing': isTicketing,
      // Don't pass created_at — let Supabase default to now()
    };
  }

}

class EmployeeOrderStore extends ChangeNotifier {
  EmployeeOrderStore._();

  static final EmployeeOrderStore instance = EmployeeOrderStore._()
    .._orders.addAll(_initialOrders);

  static final List<EmployeeOrderEntry> _initialOrders = [
    // No initial orders by default — orders will be added at runtime.
  ];

  final EmployeeOrderRepository _repository = EmployeeOrderRepository();
  final List<EmployeeOrderEntry> _orders = [];

  List<EmployeeOrderEntry> get orders => List.unmodifiable(_orders);

  List<EmployeeOrderEntry> get activeOrders =>
      _orders.where((order) => order.status == 'ordered').toList();

  List<EmployeeOrderEntry> get historyOrders => _orders
      .where(
          (order) => order.status == 'delivered' || order.status == 'rejected')
      .toList();

  void addOrder(EmployeeOrderEntry order) {
    // Remove any existing order with same id to avoid duplicates
    _orders.removeWhere((o) => o.orderId == order.orderId);
    _orders.insert(0, order);
    notifyListeners();
  }

  Future<void> saveOrder(
    EmployeeOrderEntry order, {
    String? userId,
  }) async {
    final createdOrder = await _repository.createOrder(order, userId: userId);
    addOrder(createdOrder);
  }

  Future<void> loadOrdersForEmployee(String employeeId) async {
    final orders = await _repository.fetchOrdersByEmployee(employeeId);
    _orders
      ..clear()
      ..addAll(orders);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String status) {
    final index = _orders.indexWhere((order) => order.orderId == orderId);
    if (index == -1) return;

    final existing = _orders[index];
    _orders[index] = EmployeeOrderEntry(
      orderId: existing.orderId,
      employeeId: existing.employeeId,
      userName: existing.userName,
      shopId: existing.shopId,
      shopName: existing.shopName,
      orderIntent: existing.orderIntent,
      items: existing.items,
      amount: existing.amount,
      status: status,
      pickupSlot: existing.pickupSlot,
      isTicketing: existing.isTicketing,
      createdAt: existing.createdAt,
    );

    notifyListeners();
  }
}
