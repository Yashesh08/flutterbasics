import 'dart:convert';
import 'package:course_system_crud/models/order.dart';
import 'package:course_system_crud/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Kitchen Queue ETA Prediction Tests', () {
    const baseUrl = 'http://localhost:3000';
    final orderService = OrderService(baseUrl: baseUrl);
    final client = http.Client();

    test('GET /api/orders/queue-estimate returns dynamic kitchen queue stats and wait times', () async {
      final estimate = await orderService.fetchQueueEstimate(itemPrepMinutes: 10);

      expect(estimate['ordersInQueue'], isA<int>());
      expect(estimate['ordersAhead'], isA<int>());
      expect(estimate['queuePosition'], equals(estimate['ordersAhead'] + 1));
      expect(estimate['queueWaitMinutes'], isA<int>());
      expect(estimate['itemPrepMinutes'], equals(10));
      expect(estimate['bufferMinutes'], equals(3));
      expect(
        estimate['totalEtaMinutes'],
        equals(10 + (estimate['queueWaitMinutes'] as int) + 3),
      );
      expect(estimate['estimatedPrepTime'], contains('min'));
      expect(estimate['kitchenCapacity'], equals(2));
    });

    test('POST /api/orders predicts ETA using kitchen queue and stores queuePosition in MongoDB', () async {
      // 1. Fetch queue state right before placing order
      final queueBefore = await orderService.fetchQueueEstimate(itemPrepMinutes: 6);
      final expectedOrdersAhead = queueBefore['ordersAhead'] as int;
      final expectedQueuePosition = expectedOrdersAhead + 1;
      final expectedQueueWait = queueBefore['queueWaitMinutes'] as int;
      final expectedTotalEta = 6 + expectedQueueWait + 3;

      // 2. Place order with 6 min prep item
      final placedOrder = await orderService.placeOrder(
        studentName: 'Queue Test Student',
        studentEmail: 'queue_test_${DateTime.now().millisecondsSinceEpoch}@campus.test',
        items: [
          {
            'name': 'Paneer Sandwich',
            'price': 3.80,
            'quantity': 1,
            'prepTime': '6 min',
          }
        ],
        totalAmount: 3.80,
        orderType: 'takeaway',
      );

      // 3. Verify order in MongoDB has queue prediction fields
      expect(placedOrder.id, isNotEmpty);
      expect(placedOrder.id.length, equals(24)); // Hex MongoDB ID
      expect(placedOrder.ordersAhead, equals(expectedOrdersAhead));
      expect(placedOrder.queuePosition, equals(expectedQueuePosition));
      expect(placedOrder.queueWaitTime, equals('$expectedQueueWait min'));
      expect(placedOrder.estimatedPrepTime, equals('$expectedTotalEta min'));
      expect(placedOrder.expectedReadyAt, isNotNull);

      // 4. Verify the queue position is reflected in GET /api/orders/my
      final myOrders = await orderService.fetchMyOrders(email: placedOrder.studentEmail);
      expect(myOrders, isNotEmpty);
      final retrieved = myOrders.firstWhere((o) => o.id == placedOrder.id);
      expect(retrieved.queuePosition, equals(expectedQueuePosition));
      expect(retrieved.ordersAhead, equals(expectedOrdersAhead));
      expect(retrieved.queueWaitTime, equals('$expectedQueueWait min'));
      expect(retrieved.estimatedPrepTime, equals('$expectedTotalEta min'));

      // 5. Clean up by marking order collected
      await client.patch(
        Uri.parse('$baseUrl/api/orders/${placedOrder.id}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'collected'}),
      );
    });

    test('Order model correctly exposes queue badges and human-readable summaries', () {
      const orderInLine = Order(
        id: 'ord-123',
        studentName: 'Test Student',
        studentEmail: 'student@test.com',
        items: [],
        totalAmount: 10.0,
        status: 'pending',
        queuePosition: 4,
        ordersAhead: 3,
        queueWaitTime: '6 min',
        estimatedPrepTime: '19 min',
      );

      expect(orderInLine.queuePositionBadge, equals('Queue #4'));
      expect(orderInLine.queueSummary, equals('3 orders ahead in kitchen queue'));
      expect(orderInLine.queueWaitBreakdown, equals('Queue wait: ~6 min • Est. Total: 19 min'));

      const firstOrder = Order(
        id: 'ord-124',
        studentName: 'First Student',
        studentEmail: 'first@test.com',
        items: [],
        totalAmount: 5.0,
        status: 'pending',
        queuePosition: 1,
        ordersAhead: 0,
        queueWaitTime: '0 min',
        estimatedPrepTime: '11 min',
      );

      expect(firstOrder.queuePositionBadge, equals('Queue #1'));
      expect(firstOrder.queueSummary, equals('First in kitchen queue (Immediate prep)'));
    });
  });
}
