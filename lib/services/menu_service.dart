import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';

class MenuService {
  MenuService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:3000',
            );

  final http.Client _client;
  final String _baseUrl;

  static const List<MenuItem> fallbackMenuItems = [
    MenuItem(
      id: 'veg-wrap',
      name: 'Veggie Wrap',
      category: 'Meals',
      price: 4.50,
      prepTime: '8 min',
      imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
      available: true,
    ),
    MenuItem(
      id: 'chicken-rice',
      name: 'Chicken Rice Bowl',
      category: 'Meals',
      price: 6.75,
      prepTime: '12 min',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      available: true,
    ),
    MenuItem(
      id: 'paneer-sandwich',
      name: 'Paneer Sandwich',
      category: 'Snacks',
      price: 3.80,
      prepTime: '6 min',
      imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400',
      available: true,
    ),
    MenuItem(
      id: 'samosa',
      name: 'Crispy Samosa',
      category: 'Snacks',
      price: 1.25,
      prepTime: '4 min',
      imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
      available: true,
    ),
    MenuItem(
      id: 'cold-coffee',
      name: 'Cold Coffee',
      category: 'Drinks',
      price: 2.50,
      prepTime: '3 min',
      imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=400',
      available: true,
    ),
    MenuItem(
      id: 'lemonade',
      name: 'Fresh Lemonade',
      category: 'Drinks',
      price: 1.80,
      prepTime: '2 min',
      imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=400',
      available: true,
    ),
    MenuItem(
      id: 'chocolate-brownie',
      name: 'Chocolate Brownie',
      category: 'Desserts',
      price: 3.00,
      prepTime: '5 min',
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400',
      available: true,
    ),
  ];

  Future<List<MenuItem>> fetchMenuItems() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/api/menu'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return fallbackMenuItems;
    } catch (_) {
      // Fallback to offline/seeded items if API server is unreachable
      return fallbackMenuItems;
    }
  }
}
