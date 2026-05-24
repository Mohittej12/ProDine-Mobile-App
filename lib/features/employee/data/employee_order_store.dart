import 'package:flutter/foundation.dart';

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
}

class EmployeeOrderStore extends ChangeNotifier {
  EmployeeOrderStore._();

  static final EmployeeOrderStore instance = EmployeeOrderStore._()
    .._orders.addAll(_initialOrders);

  static final List<EmployeeOrderEntry> _initialOrders = [
    // No initial orders by default — orders will be added at runtime.
  ];

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
