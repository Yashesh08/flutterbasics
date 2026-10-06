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
}
