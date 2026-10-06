import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  MenuProvider({MenuService? menuService})
      : _menuService = menuService ?? MenuService();

  final MenuService _menuService;

  List<MenuItem> _items = [];
  bool _loading = false;
  String? _error;

  List<MenuItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadMenu({bool force = false}) async {
    if (_loading) return;
    if (_items.isNotEmpty && !force) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _menuService.fetchMenuItems();
      _items = fetched;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (_items.isEmpty) {
        _items = List.from(MenuService.fallbackMenuItems);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<MenuItem> addItem(MenuItem item, {String? token}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _menuService.createMenuItem(item, token: token);
      _items.removeWhere((i) => i.id == created.id);
      _items.insert(0, created);
      _loading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<MenuItem> updateItem(MenuItem item, {String? token}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _menuService.updateMenuItem(item, token: token);
      final index = _items.indexWhere((i) => i.id == updated.id);
      if (index != -1) {
        _items[index] = updated;
      }
      _loading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteItem(String id, {String? token}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _menuService.deleteMenuItem(id, token: token);
      if (success) {
        _items.removeWhere((i) => i.id == id);
      }
      _loading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleAvailability(MenuItem item, {String? token}) async {
    final updated = item.copyWith(available: !item.available);
    // Optimistic update
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = updated;
      notifyListeners();
    }

    try {
      await _menuService.updateMenuItem(updated, token: token);
    } catch (e) {
      // Revert if failed
      if (index != -1) {
        _items[index] = item;
        notifyListeners();
      }
      rethrow;
    }
  }
}
