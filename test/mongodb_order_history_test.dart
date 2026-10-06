import 'dart:convert';
import 'package:course_system_crud/models/order.dart';
import 'package:course_system_crud/providers/order_provider.dart';
import 'package:course_system_crud/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Real MongoDB Order History (Day 4 - Person A) Integration Tests', () {
    const baseUrl = 'http://localhost:3000';
    final orderService = OrderService(baseUrl: baseUrl);
    final client = http.Client();

    test('GET /api/orders/my returns student orders directly from MongoDB with status & ETA', () async {
      final uniqueEmail = 'student_${DateTime.now().millisecondsSinceEpoch}@campus.test';

      // 1. Place a new order for this student in MongoDB
      final createdOrder = await orderService.placeOrder(
        studentName: 'Test Student Day4',
        studentEmail: uniqueEmail,
        items: [
          {
            'name': 'Cold Coffee',
            'price': 2.50,
            'quantity': 2,
            'prepTime': '3 min',
          },
          {
            'name': 'Paneer Sandwich',
            'price': 3.80,
            'quantity': 1,
            'prepTime': '6 min',
          },
        ],
        totalAmount: 8.80,
        orderType: 'takeaway',
        specialInstructions: 'Less ice please',
      );

      expect(createdOrder.id, isNotEmpty);
      expect(createdOrder.id.length, equals(24)); // MongoDB ObjectId hex length
      expect(createdOrder.status, equals('pending'));
      final expectedQueueWait = createdOrder.ordersAhead == 0
          ? 0
          : ((createdOrder.ordersAhead + 1) ~/ 2) * 3;
      final expectedEta = 6 + expectedQueueWait + 3;
      expect(createdOrder.estimatedPrepTime, equals('$expectedEta min'));

      // 2. Fetch student's own orders using GET /api/orders/my?email=...
      final myOrdersByEmail = await orderService.fetchMyOrders(email: uniqueEmail);
      expect(myOrdersByEmail, isNotEmpty);
      expect(myOrdersByEmail.any((o) => o.id == createdOrder.id), isTrue);

      final retrieved = myOrdersByEmail.firstWhere((o) => o.id == createdOrder.id);
      expect(retrieved.studentEmail, equals(uniqueEmail));
      expect(retrieved.studentName, equals('Test Student Day4'));
      expect(retrieved.items.length, equals(2));
      expect(retrieved.totalAmount, equals(8.80));
      expect(retrieved.orderType, equals('takeaway'));
      expect(retrieved.isTakeaway, isTrue);
      expect(retrieved.status, equals('pending'));
      expect(retrieved.specialInstructions, equals('Less ice please'));
      expect(retrieved.expectedReadyAt, isNotNull);

      // 3. Update status in MongoDB via PATCH /api/orders/:id/status to 'preparing'
      final prepPatchResponse = await client.patch(
        Uri.parse('$baseUrl/api/orders/${createdOrder.id}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'preparing'}),
      );
      expect(prepPatchResponse.statusCode, equals(200));

      // 4. Re-fetch via GET /api/orders/my and verify updated status from MongoDB
      final updatedOrders = await orderService.fetchMyOrders(email: uniqueEmail);
      final preparingOrder = updatedOrders.firstWhere((o) => o.id == createdOrder.id);
      expect(preparingOrder.status, equals('preparing'));
      expect(preparingOrder.statusLabel, equals('Preparing'));

      // 5. Update status to 'ready'
      final readyPatchResponse = await client.patch(
        Uri.parse('$baseUrl/api/orders/${createdOrder.id}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'ready'}),
      );
      expect(readyPatchResponse.statusCode, equals(200));

      // 6. Test with OrderProvider loadMyOrders
      final provider = OrderProvider(orderService: orderService);
      await provider.loadMyOrders(email: uniqueEmail);

      expect(provider.orders.any((o) => o.id == createdOrder.id), isTrue);
      expect(provider.activeOrders.any((o) => o.id == createdOrder.id), isTrue);
      expect(provider.completedOrders.any((o) => o.id == createdOrder.id), isFalse);

      // 7. Complete the order -> 'collected'
      final collectedPatchResponse = await client.patch(
        Uri.parse('$baseUrl/api/orders/${createdOrder.id}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'collected'}),
      );
      expect(collectedPatchResponse.statusCode, equals(200));

      // 8. Re-load in provider and verify it moves from active to completed/past
      await provider.loadMyOrders(email: uniqueEmail);
      expect(provider.activeOrders.any((o) => o.id == createdOrder.id), isFalse);
      expect(provider.completedOrders.any((o) => o.id == createdOrder.id), isTrue);
      final pastOrder = provider.completedOrders.firstWhere((o) => o.id == createdOrder.id);
      expect(pastOrder.status, equals('collected'));
      expect(pastOrder.statusLabel, equals('Collected'));
    });

    test('GET /api/orders/my works with Authorization Bearer header', () async {
      // Fetch orders using seed student token
      final orders = await orderService.fetchMyOrders(
        token: 'seed-session-seed-student-1',
      );

      // Should return student@campus.test's orders directly from MongoDB
      expect(orders, isA<List<Order>>());
      for (final order in orders) {
        expect(order.studentEmail, equals('student@campus.test'));
        expect(order.id.length, equals(24)); // Hex MongoDB ID
      }
    });

    test('GET /api/orders/my filters by status in MongoDB', () async {
      final pendingOrders = await orderService.fetchMyOrders(
        email: 'student@campus.test',
        status: 'pending',
      );

      for (final order in pendingOrders) {
        expect(order.status, equals('pending'));
      }
    });
  });
}
