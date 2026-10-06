import 'package:course_system_crud/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Real MongoDB Order Creation & ETA Integration Tests', () {
    final orderService = OrderService(baseUrl: 'http://localhost:3000');

    test('creates order in MongoDB with calculated ETA = MAX(prepTime) + buffer', () async {
      // Items with different prep times: 6 min and 12 min
      final cartItems = [
        {
          'name': 'Paneer Sandwich',
          'price': 3.80,
          'quantity': 1,
          'prepTime': '6 min',
        },
        {
          'name': 'Chicken Rice Bowl',
          'price': 6.75,
          'quantity': 2,
          'prepTime': '12 min',
        },
      ];

      final beforeCreation = DateTime.now();

      final order = await orderService.placeOrder(
        studentName: 'Asha Patel',
        studentEmail: 'student@campus.test',
        items: cartItems,
        totalAmount: 17.30,
        orderType: 'takeaway',
        specialInstructions: 'Pack in paper bag please',
      );

      // 1. Verify Order ID is a 24-character hexadecimal MongoDB ObjectId
      expect(order.id, isNotEmpty);
      expect(order.id.length, equals(24));

      // 2. Verify Order Type
      expect(order.orderType, equals('takeaway'));
      expect(order.isTakeaway, isTrue);
      expect(order.formattedOrderType, equals('Takeaway'));

      // 3. Verify ETA calculation: MAX(6, 12) + queue wait + 3 buffer
      final expectedQueueWait = order.ordersAhead == 0
          ? 0
          : ((order.ordersAhead + 1) ~/ 2) * 3;
      final expectedTotalEta = 12 + expectedQueueWait + 3;

      expect(order.ordersAhead, isNonNegative);
      expect(order.queuePosition, equals(order.ordersAhead + 1));
      expect(order.estimatedPrepTime, equals('$expectedTotalEta min'));
      expect(order.expectedReadyAt, isNotNull);

      // expectedReadyAt should be approximately beforeCreation + expectedTotalEta minutes
      final differenceMinutes =
          order.expectedReadyAt!.difference(beforeCreation).inMinutes;
      expect(differenceMinutes, inInclusiveRange(expectedTotalEta - 1, expectedTotalEta + 1));

      // 4. Verify order is retrievable from MongoDB
      final fetchedOrders =
          await orderService.fetchOrders(email: 'student@campus.test');
      expect(fetchedOrders.any((o) => o.id == order.id), isTrue);

      final retrieved = fetchedOrders.firstWhere((o) => o.id == order.id);
      expect(retrieved.orderType, equals('takeaway'));
      expect(retrieved.items.length, equals(2));
      expect(retrieved.totalAmount, equals(17.30));
      expect(retrieved.queuePosition, equals(order.queuePosition));
      expect(retrieved.expectedReadyAt, isNotNull);
    });

    test('creates dine-in order in MongoDB with single-item prep time ETA', () async {
      final cartItems = [
        {
          'name': 'Crispy Samosa',
          'price': 1.25,
          'quantity': 3,
          'prepTime': '4 min',
        },
      ];

      final order = await orderService.placeOrder(
        studentName: 'Ravi Kumar',
        studentEmail: 'staff@campus.test',
        items: cartItems,
        totalAmount: 3.75,
        orderType: 'dine-in',
      );

      expect(order.id.length, equals(24));
      expect(order.orderType, equals('dine-in'));
      expect(order.isDineIn, isTrue);

      // ETA: 4 min + queue wait + 3 buffer
      final expectedQueueWait = order.ordersAhead == 0
          ? 0
          : ((order.ordersAhead + 1) ~/ 2) * 3;
      final expectedTotal = 4 + expectedQueueWait + 3;
      expect(order.estimatedPrepTime, equals('$expectedTotal min'));
    });
  });
}
