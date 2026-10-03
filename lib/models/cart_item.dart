import 'menu_item.dart';

class CartItem {
  CartItem({
    required this.item,
    this.quantity = 1,
  });

  final MenuItem item;
  int quantity;

  double get totalPrice => item.price * quantity;

  Map<String, dynamic> toJson() => {
        'item': item.toJson(),
        'quantity': quantity,
        'totalPrice': totalPrice,
      };
}
