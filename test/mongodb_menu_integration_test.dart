import 'package:course_system_crud/models/menu_item.dart';
import 'package:course_system_crud/services/menu_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Real MongoDB Backend Integration Tests', () {
    final menuService = MenuService(baseUrl: 'http://localhost:3000');

    test('fetches real menu items from MongoDB', () async {
      final items = await menuService.fetchMenuItems();
      expect(items, isNotEmpty);
      expect(items.any((i) => i.name == 'Veggie Wrap'), isTrue);
      // Verify items have real MongoDB ObjectIds (24 hex characters)
      expect(items.first.id.length, equals(24));
    });

    test('creates, updates, and deletes item in MongoDB', () async {
      // 1. Create in MongoDB
      const testItem = MenuItem(
        id: '',
        name: 'MongoDB Paneer Tikka',
        category: 'Snacks',
        price: 4.80,
        prepTime: '9 min',
        imageUrl: 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400',
        available: true,
      );

      final created = await menuService.createMenuItem(
        testItem,
        token: 'seed-session-seed-staff-1',
      );

      expect(created.id, isNotEmpty);
      expect(created.id.length, equals(24)); // Real MongoDB ObjectId!
      expect(created.name, equals('MongoDB Paneer Tikka'));
      expect(created.price, equals(4.80));

      // 2. Verify it shows in fetchMenuItems from MongoDB
      final afterCreate = await menuService.fetchMenuItems();
      expect(afterCreate.any((i) => i.id == created.id), isTrue);

      // 3. Update in MongoDB
      final updated = await menuService.updateMenuItem(
        created.copyWith(price: 5.20, available: false),
        token: 'seed-session-seed-staff-1',
      );
      expect(updated.price, equals(5.20));
      expect(updated.available, isFalse);

      // 4. Delete from MongoDB
      final deleteSuccess = await menuService.deleteMenuItem(
        created.id,
        token: 'seed-session-seed-staff-1',
      );
      expect(deleteSuccess, isTrue);

      // 5. Verify it is gone from MongoDB
      final afterDelete = await menuService.fetchMenuItems();
      expect(afterDelete.any((i) => i.id == created.id), isFalse);
    });
  });
}
