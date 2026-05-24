import 'package:pro_dine/data/models/order_model.dart';
import 'package:pro_dine/data/mock/mock_menu_items.dart';

final List<OrderModel> mockOrders = [
  OrderModel(
    orderId: 'ORD-ED-20458',
    userId: '1',
    employeeId: 'PD1001',
    userName: 'Sarah',
    shopId: '1',
    shopName: 'Meal Counter',
    items: [mockMenuItems[0]], // Idli
    amount: 60,
    orderType: 'regular',
    paymentType: 'paid',
    paymentStatus: 'success',
    status: 'Delivered',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  OrderModel(
    orderId: 'ORD-ED-20459',
    userId: '1',
    employeeId: 'PD1001',
    userName: 'Sarah',
    shopId: '2',
    shopName: 'Tuck Shop',
    items: [mockMenuItems[6]], // Chicken Biryani
    amount: 220,
    orderType: 'regular',
    paymentType: 'paid',
    paymentStatus: 'success',
    status: 'Rejected',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  OrderModel(
    orderId: 'ORD-ED-20460',
    userId: '1',
    employeeId: 'PD1001',
    userName: 'Sarah',
    shopId: '1',
    shopName: 'Meal Counter',
    items: [mockMenuItems[3]], // Veg Meals
    amount: 140,
    orderType: 'ticketing',
    paymentType: 'free',
    paymentStatus: 'notRequired',
    status: 'Delivered',
    createdAt: DateTime.now(),
  ),
];