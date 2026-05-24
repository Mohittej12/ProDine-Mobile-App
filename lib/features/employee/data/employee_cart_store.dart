import 'package:flutter/foundation.dart';

class EmployeeCartEntry {
  const EmployeeCartEntry({
    required this.id,
    required this.name,
    required this.shopName,
    required this.meal,
    required this.price,
    required this.quantity,
    required this.imagePath,
  });

  final String id;
  final String name;
  final String shopName;
  final String meal;
  final int price;
  final int quantity;
  final String imagePath;

  EmployeeCartEntry copyWith({
    String? id,
    String? name,
    String? shopName,
    String? meal,
    int? price,
    int? quantity,
    String? imagePath,
  }) {
    return EmployeeCartEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      shopName: shopName ?? this.shopName,
      meal: meal ?? this.meal,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class EmployeeCartStore extends ChangeNotifier {
  EmployeeCartStore._();

  static final EmployeeCartStore instance = EmployeeCartStore._()
    .._items.addAll(_initialItems);

  static const String defaultFoodImage = 'assets/images/auth_login_header.png';

  static final List<EmployeeCartEntry> _initialItems = [];

  final List<EmployeeCartEntry> _items = [];
  final Map<String, String> _pickupSelections = {};
  bool _isTicketingMode = false;

  bool get isTicketingMode => _isTicketingMode;

  void setTicketingMode(bool isTicketing) {
    if (_isTicketingMode == isTicketing) return;
    _isTicketingMode = isTicketing;
    notifyListeners();
  }

  List<EmployeeCartEntry> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold<int>(0, (sum, item) => sum + item.quantity);

  String? selectedPickupSlot(String shopName) => _pickupSelections[shopName];

  void setPickupSlot(String shopName, String? timeSlot) {
    if (timeSlot == null) {
      _pickupSelections.remove(shopName);
    } else {
      _pickupSelections[shopName] = timeSlot;
    }
    notifyListeners();
  }

  Map<String, String> get pickupSelections =>
      Map.unmodifiable(_pickupSelections);

  void addItem({
    required String id,
    required String name,
    required String shopName,
    required String meal,
    required int price,
    required String imagePath,
  }) {
    final index = _items.indexWhere((item) => item.id == id);

    if (index == -1) {
      _items.add(
        EmployeeCartEntry(
          id: id,
          name: name,
          shopName: shopName,
          meal: meal,
          price: price,
          quantity: 1,
          imagePath: imagePath,
        ),
      );
    } else {
      final item = _items[index];
      _items[index] = item.copyWith(quantity: item.quantity + 1);
    }

    notifyListeners();
  }

  void increment(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _items[index];
    _items[index] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
  }

  void decrement(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _items[index];
    if (item.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = item.copyWith(quantity: item.quantity - 1);
    }
    notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void removeShop(String shopName) {
    _items.removeWhere((item) => item.shopName == shopName);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty && _pickupSelections.isEmpty) return;
    _items.clear();
    _pickupSelections.clear();
    notifyListeners();
  }
}
