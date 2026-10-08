import 'package:flutter/material.dart';

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.prepTime,
    required this.imageUrl,
    this.available = true,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String prepTime;
  final String imageUrl;
  final bool available;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name'] as String? ?? 'Unnamed item',
        category: json['category'] as String? ?? 'Meals',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        prepTime: json['prepTime'] as String? ?? '10 min',
        imageUrl: json['imageUrl'] as String? ?? '',
        available: json['available'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'prepTime': prepTime,
        'imageUrl': imageUrl,
        'available': available,
      };

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? prepTime,
    String? imageUrl,
    bool? available,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      prepTime: prepTime ?? this.prepTime,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
    );
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'meals':
        return Icons.rice_bowl;
      case 'snacks':
        return Icons.breakfast_dining;
      case 'drinks':
      case 'beverages':
        return Icons.local_cafe;
      case 'desserts':
        return Icons.cake;
      case 'combos':
        return Icons.lunch_dining;
      default:
        return Icons.fastfood;
    }
  }

  /// Formatted price with Indian Rupee symbol
  String get formattedPrice {
    final isInt = price.truncateToDouble() == price;
    return '₹${price.toStringAsFixed(isInt ? 0 : 2)}';
  }

  /// Rating derived deterministically from the item
  double get rating {
    final offset = (name.hashCode.abs() % 8) / 10.0;
    return (4.2 + offset).clamp(4.0, 5.0);
  }

  /// Estimated review count
  int get reviewCount => 30 + (name.hashCode.abs() % 180);

  /// Whether this item is featured / popular
  bool get isPopular => (name.hashCode.abs() % 3 == 0) || category.toLowerCase() == 'meals';

  /// Preparation minutes parsed from prepTime string
  int get prepMinutes {
    final match = RegExp(r'\d+').firstMatch(prepTime);
    return match != null ? int.parse(match.group(0)!) : 10;
  }

  /// Natural description for food details bottom sheet
  String get description {
    switch (category.toLowerCase()) {
      case 'drinks':
      case 'beverages':
        return 'Refreshing and freshly chilled beverage prepared on demand. The perfect companion for your campus study breaks.';
      case 'snacks':
        return 'Crispy, savory snack prepared fresh with authentic canteen spices. Perfect for a quick bite between lectures.';
      case 'desserts':
        return 'Indulgent, freshly prepared sweet treat to brighten your day and finish your meal on a delightful note.';
      case 'meals':
      case 'combos':
        return 'Wholesome, filling meal crafted with quality ingredients to keep you powered throughout your busy campus routine.';
      default:
        return 'Delicious canteen specialty prepared fresh upon order by our kitchen staff.';
    }
  }

  /// Mood filter helpers
  bool get isQuickBite => prepMinutes <= 8 || category.toLowerCase() == 'snacks';
  bool get isSweet =>
      category.toLowerCase() == 'desserts' ||
      name.toLowerCase().contains('sweet') ||
      name.toLowerCase().contains('brownie') ||
      name.toLowerCase().contains('chocolate');
  bool get isDrink =>
      category.toLowerCase() == 'drinks' ||
      category.toLowerCase() == 'beverages' ||
      name.toLowerCase().contains('coffee') ||
      name.toLowerCase().contains('tea') ||
      name.toLowerCase().contains('lemonade') ||
      name.toLowerCase().contains('shake');
  bool get isProperMeal =>
      category.toLowerCase() == 'meals' ||
      category.toLowerCase() == 'combos' ||
      name.toLowerCase().contains('bowl') ||
      name.toLowerCase().contains('rice') ||
      name.toLowerCase().contains('thali');
  bool get isUnder100 => price < 100;
}
