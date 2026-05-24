import 'package:pro_dine/data/models/menu_item_model.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final String employeeId;
  final String userName;
  final String shopId;
  final String shopName;
  final List<MenuItemModel> items;
  final double amount;
  final String orderType; // regular or ticketing
  final String paymentType; // paid or free
  final String paymentStatus; // success or notRequired
  final String status; // Delivered or Rejected
  final DateTime createdAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.employeeId,
    required this.userName,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.amount,
    required this.orderType,
    required this.paymentType,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'],
      userId: json['userId'],
      employeeId: json['employeeId'],
      userName: json['userName'],
      shopId: json['shopId'],
      shopName: json['shopName'],
      items: (json['items'] as List<dynamic>)
          .map((item) => MenuItemModel.fromJson(item))
          .toList(),
      amount: json['amount'],
      orderType: json['orderType'],
      paymentType: json['paymentType'],
      paymentStatus: json['paymentStatus'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'employeeId': employeeId,
      'userName': userName,
      'shopId': shopId,
      'shopName': shopName,
      'items': items.map((item) => item.toJson()).toList(),
      'amount': amount,
      'orderType': orderType,
      'paymentType': paymentType,
      'paymentStatus': paymentStatus,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}