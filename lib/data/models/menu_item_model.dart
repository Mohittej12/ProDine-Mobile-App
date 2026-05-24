class MenuItemModel {
  final String id;
  final String name;
  final double price;
  final String shopId;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.shopId,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      shopId: json['shopId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'shopId': shopId,
    };
  }
}