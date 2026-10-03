import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  Map<String, CartItem> get itemMap => Map.unmodifiable(_items);

  int get itemCount =>
      _items.values.fold(0, (total, item) => total + item.quantity);

  double get totalAmount =>
      _items.values.fold(0.0, (total, item) => total + item.totalPrice);

  bool get isEmpty => _items.isEmpty;

  int getQuantity(String itemId) => _items[itemId]?.quantity ?? 0;

  void addToCart(MenuItem item) {
    if (_items.containsKey(item.id)) {
      _items[item.id]!.quantity += 1;
    } else {
      _items[item.id] = CartItem(item: item, quantity: 1);
    }
    notifyListeners();
  }

  void decrementQuantity(String itemId) {
    if (!_items.containsKey(itemId)) return;

    if (_items[itemId]!.quantity > 1) {
      _items[itemId]!.quantity -= 1;
    } else {
      _items.remove(itemId);
    }
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    if (!_items.containsKey(itemId)) return;

    if (quantity <= 0) {
      _items.remove(itemId);
    } else {
      _items[itemId]!.quantity = quantity;
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    if (_items.remove(itemId) != null) {
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
