import 'package:pro_dine/data/models/menu_item_model.dart';

final List<MenuItemModel> mockMenuItems = [
  // Meal Counter
  MenuItemModel(id: '1', name: 'Idli', price: 60, shopId: '1'),
  MenuItemModel(id: '2', name: 'Masala Dosa', price: 80, shopId: '1'),
  MenuItemModel(id: '3', name: 'Poori', price: 70, shopId: '1'),
  MenuItemModel(id: '4', name: 'Veg Meals', price: 140, shopId: '1'),
  MenuItemModel(id: '5', name: 'Breakfast Meal', price: 0, shopId: '1'),
  MenuItemModel(id: '6', name: 'Dinner Meal', price: 0, shopId: '1'),

  // Tuck Shop
  MenuItemModel(id: '7', name: 'Chicken Biryani', price: 220, shopId: '2'),
  MenuItemModel(id: '8', name: 'Veg Sandwich', price: 90, shopId: '2'),
  MenuItemModel(id: '9', name: 'Cold Coffee', price: 80, shopId: '2'),
  MenuItemModel(id: '10', name: 'Margherita Pizza', price: 160, shopId: '2'),
  MenuItemModel(id: '11', name: 'Omelette', price: 75, shopId: '2'),
];