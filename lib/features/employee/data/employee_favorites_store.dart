import 'package:flutter/foundation.dart';

class EmployeeFavoriteItem {
  const EmployeeFavoriteItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.restaurant,
    required this.meal,
    required this.category,
    required this.rating,
    required this.isVeg,
    required this.isAvailable,
    required this.imagePath,
  });

  final String id;
  final String name;
  final String price;
  final String description;
  final String restaurant;
  final String meal;
  final String category;
  final String rating;
  final bool isVeg;
  final bool isAvailable;
  final String imagePath;
}

class EmployeeFavoritesStore extends ValueNotifier<List<EmployeeFavoriteItem>> {
  EmployeeFavoritesStore._() : super(const []);

  static final EmployeeFavoritesStore instance = EmployeeFavoritesStore._();

  bool contains(String id) {
    return value.any((item) => item.id == id);
  }

  void toggle(EmployeeFavoriteItem item) {
    if (contains(item.id)) {
      value = value.where((favorite) => favorite.id != item.id).toList();
      return;
    }

    value = [...value, item];
  }

  void remove(String id) {
    value = value.where((item) => item.id != id).toList();
  }
}
