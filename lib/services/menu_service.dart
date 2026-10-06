import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import 'api_config.dart';

class MenuService {
  MenuService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? defaultApiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static final List<MenuItem> _inMemoryItems = [
    const MenuItem(
      id: 'veg-wrap',
      name: 'Veggie Wrap',
      category: 'Meals',
      price: 4.50,
      prepTime: '8 min',
      imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
      available: true,
    ),
    const MenuItem(
      id: 'chicken-rice',
      name: 'Chicken Rice Bowl',
      category: 'Meals',
      price: 6.75,
      prepTime: '12 min',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      available: true,
    ),
    const MenuItem(
      id: 'paneer-sandwich',
      name: 'Paneer Sandwich',
      category: 'Snacks',
      price: 3.80,
      prepTime: '6 min',
      imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400',
      available: true,
    ),
    const MenuItem(
      id: 'samosa',
      name: 'Crispy Samosa',
      category: 'Snacks',
      price: 1.25,
      prepTime: '4 min',
      imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
      available: true,
    ),
    const MenuItem(
      id: 'cold-coffee',
      name: 'Cold Coffee',
      category: 'Drinks',
      price: 2.50,
      prepTime: '3 min',
      imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=400',
      available: true,
    ),
    const MenuItem(
      id: 'lemonade',
      name: 'Fresh Lemonade',
      category: 'Drinks',
      price: 1.80,
      prepTime: '2 min',
      imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=400',
      available: true,
    ),
    const MenuItem(
      id: 'chocolate-brownie',
      name: 'Chocolate Brownie',
      category: 'Desserts',
      price: 3.00,
      prepTime: '5 min',
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400',
      available: true,
    ),
  ];

  static List<MenuItem> get fallbackMenuItems => List.unmodifiable(_inMemoryItems);

  Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'x-user-role': 'staff',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      headers['Authorization'] = 'Bearer seed-session-seed-staff-1';
    }
    return headers;
  }

  Future<List<MenuItem>> fetchMenuItems() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/api/menu'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final items = data
            .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _inMemoryItems.clear();
        _inMemoryItems.addAll(items);
        return items;
      }
      return List<MenuItem>.from(_inMemoryItems);
    } catch (_) {
      // Fallback to offline/seeded items if API server is unreachable
      return List<MenuItem>.from(_inMemoryItems);
    }
  }

  Future<MenuItem> createMenuItem(MenuItem item, {String? token}) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/menu'),
          headers: _buildHeaders(token: token),
          body: jsonEncode({
            'name': item.name,
            'category': item.category,
            'price': item.price,
            'prepTime': item.prepTime,
            'imageUrl': item.imageUrl,
            'available': item.available,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 201) {
      final created = MenuItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      _inMemoryItems.insert(0, created);
      return created;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Failed to save menu item to MongoDB (${response.statusCode})');
    }
  }

  Future<MenuItem> updateMenuItem(MenuItem item, {String? token}) async {
    final response = await _client
        .put(
          Uri.parse('$_baseUrl/api/menu/${item.id}'),
          headers: _buildHeaders(token: token),
          body: jsonEncode({
            'name': item.name,
            'category': item.category,
            'price': item.price,
            'prepTime': item.prepTime,
            'imageUrl': item.imageUrl,
            'available': item.available,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final updated = MenuItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      final index = _inMemoryItems.indexWhere((i) => i.id == updated.id);
      if (index != -1) {
        _inMemoryItems[index] = updated;
      }
      return updated;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Failed to update menu item in MongoDB (${response.statusCode})');
    }
  }

  Future<bool> deleteMenuItem(String id, {String? token}) async {
    final response = await _client
        .delete(
          Uri.parse('$_baseUrl/api/menu/$id'),
          headers: _buildHeaders(token: token),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      _inMemoryItems.removeWhere((i) => i.id == id);
      return true;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Failed to delete menu item from MongoDB (${response.statusCode})');
    }
  }
}
