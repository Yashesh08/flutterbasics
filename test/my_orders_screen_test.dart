import 'dart:convert';
import 'package:course_system_crud/providers/order_provider.dart';
import 'package:course_system_crud/screens/my_orders_screen.dart';
import 'package:course_system_crud/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

void main() {
  final now = DateTime.now();

  final sampleActiveOrderJson = {
    'id': '6ac3d54c816814c07cbeb49b',
    'studentName': 'Asha Patel',
    'studentEmail': 'student@campus.test',
    'items': [
      {
        'menuItemId': '6ac3d54c816814c07cbeb499',
        'name': 'Paneer Sandwich',
        'price': 3.80,
        'quantity': 1,
        'subtotal': 3.80,
        'prepTime': '6 min',
      },
      {
        'menuItemId': '6ac3d54c816814c07cbeb49a',
        'name': 'Chicken Rice Bowl',
        'price': 6.75,
        'quantity': 2,
        'subtotal': 13.50,
        'prepTime': '12 min',
      },
    ],
    'totalAmount': 17.30,
    'orderType': 'takeaway',
    'status': 'preparing',
    'estimatedPrepTime': '15 min',
    'expectedReadyAt': now.add(const Duration(minutes: 15)).toIso8601String(),
    'createdAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
    'specialInstructions': 'Pack in paper bag please',
  };

  final samplePastOrderJson = {
    'id': '6ac3d392816814c07cbeb48f',
    'studentName': 'Asha Patel',
    'studentEmail': 'student@campus.test',
    'items': [
      {
        'menuItemId': '6ac3b12bb30f61620c5b1371',
        'name': 'Cold Coffee',
        'price': 2.50,
        'quantity': 2,
        'subtotal': 5.00,
        'prepTime': '3 min',
      },
    ],
    'totalAmount': 5.00,
    'orderType': 'dine-in',
    'status': 'collected',
    'estimatedPrepTime': '6 min',
    'expectedReadyAt': now.subtract(const Duration(minutes: 30)).toIso8601String(),
    'createdAt': now.subtract(const Duration(minutes: 40)).toIso8601String(),
  };

  testWidgets('MyOrdersScreen displays active and past orders with status badges and ETA', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/api/orders/my') {
        return http.Response(
          jsonEncode([sampleActiveOrderJson, samplePastOrderJson]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final orderService = OrderService(client: mockClient, baseUrl: 'http://test');
    final orderProvider = OrderProvider(orderService: orderService);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: orderProvider,
        child: const MaterialApp(
          home: MyOrdersScreen(
            studentEmail: 'student@campus.test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Tabs showing counts
    expect(find.text('Active (1)'), findsOneWidget);
    expect(find.text('Past (1)'), findsOneWidget);

    // 2. Verify active order card content
    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Takeaway'), findsOneWidget);
    expect(find.text('1× Paneer Sandwich'), findsOneWidget);
    expect(find.text('2× Chicken Rice Bowl'), findsOneWidget);
    expect(find.text('₹17.30'), findsOneWidget);
    expect(find.textContaining('Estimated Ready: 15 min'), findsOneWidget);

    // 3. Tap active order card to open order detail bottom sheet
    await tester.tap(find.text('Preparing'));
    await tester.pumpAndSettle();

    // Verify detail sheet opened
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('MongoDB ID: 6ac3d54c816814c07cbeb49b'), findsOneWidget);
    expect(find.text('Pack in paper bag please'), findsOneWidget);
    expect(find.text('Prep: 6 min'), findsOneWidget);
    expect(find.text('Prep: 12 min'), findsOneWidget);

    // Close bottom sheet
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // 4. Switch to Past orders tab
    await tester.tap(find.text('Past (1)'));
    await tester.pumpAndSettle();

    // Verify past order card
    expect(find.text('Collected'), findsOneWidget);
    expect(find.text('Dine-In'), findsOneWidget);
    expect(find.text('2× Cold Coffee'), findsOneWidget);
    expect(find.text('₹5.00'), findsNWidgets(2));
  });

  testWidgets('MyOrdersScreen displays empty state when student has no orders', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/api/orders/my') {
        return http.Response(
          jsonEncode([]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final orderService = OrderService(client: mockClient, baseUrl: 'http://test');
    final orderProvider = OrderProvider(orderService: orderService);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: orderProvider,
        child: const MaterialApp(
          home: MyOrdersScreen(
            studentEmail: 'new_student@campus.test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active (0)'), findsOneWidget);
    expect(find.text('Past (0)'), findsOneWidget);
    expect(find.text('No active orders right now'), findsOneWidget);

    // Switch to Past tab
    await tester.tap(find.text('Past (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No past orders yet'), findsOneWidget);
  });
}
