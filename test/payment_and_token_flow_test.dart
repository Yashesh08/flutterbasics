import 'package:course_system_crud/models/menu_item.dart';
import 'package:course_system_crud/models/order.dart';
import 'package:course_system_crud/providers/cart_provider.dart';
import 'package:course_system_crud/providers/order_provider.dart';
import 'package:course_system_crud/screens/checkout_screen.dart';
import 'package:course_system_crud/screens/order_confirmation_screen.dart';
import 'package:course_system_crud/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Payment & Order Token Flow (Online vs Offline Cash)', () {
    final orderService = OrderService(baseUrl: 'http://localhost:3000');

    test('Online payment: generates token automatically and dispatches to kitchen queue', () async {
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch;
      final studentEmail = 'student.online.$uniqueSuffix@campus.test';

      final order = await orderService.placeOrder(
        studentName: 'Online Student',
        studentEmail: studentEmail,
        items: [
          {
            'name': 'Paneer Tikka Roll',
            'price': 4.50,
            'quantity': 2,
            'prepTime': '8 min',
          }
        ],
        totalAmount: 9.00,
        paymentMethod: 'online',
        orderType: 'takeaway',
      );

      // Verify Online payment rules
      expect(order.id, isNotEmpty);
      expect(order.paymentMethod, equals('online'));
      expect(order.isOnlinePayment, isTrue);
      expect(order.paymentStatus, equals('paid'));
      expect(order.isPaid, isTrue);

      // Token generated automatically
      expect(order.tokenNumber, isNotNull);
      expect(order.tokenNumber, startsWith('T-'));
      expect(order.hasToken, isTrue);
      expect(order.tokenDisplay, equals('#${order.tokenNumber}'));

      // Order directly dispatched to kitchen queue
      expect(order.status, equals('pending'));
      expect(order.queuePosition, isNotNull);
      expect(order.queuePosition, isPositive);
      expect(order.estimatedPrepTime, isNotEmpty);
    });

    test('Offline payment: creates order awaiting cash payment with NO kitchen queue or token', () async {
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch;
      final studentEmail = 'student.offline.$uniqueSuffix@campus.test';

      final offlineOrder = await orderService.placeOrder(
        studentName: 'Cash Student',
        studentEmail: studentEmail,
        items: [
          {
            'name': 'Masala Dosa',
            'price': 3.50,
            'quantity': 1,
            'prepTime': '6 min',
          }
        ],
        totalAmount: 3.50,
        paymentMethod: 'offline',
        orderType: 'dine-in',
      );

      // Verify Offline payment rules
      expect(offlineOrder.id, isNotEmpty);
      expect(offlineOrder.paymentMethod, equals('offline'));
      expect(offlineOrder.isOfflinePayment, isTrue);
      expect(offlineOrder.paymentStatus, equals('pending_payment'));
      expect(offlineOrder.isPaid, isFalse);
      expect(offlineOrder.isAwaitingPayment, isTrue);

      // NO token yet (must collect from counter staff)
      expect(offlineOrder.tokenNumber, isNull);
      expect(offlineOrder.hasToken, isFalse);
      expect(offlineOrder.tokenDisplay, equals('Pay at Counter'));
      expect(offlineOrder.status, equals('awaiting_payment'));
      expect(offlineOrder.statusLabel, equals('Awaiting Cash Payment'));

      // Now counter staff collects cash and issues token
      final tokenizedOrder = await orderService.issueOrderToken(offlineOrder.id);

      // Verify after staff issues token:
      expect(tokenizedOrder.id, equals(offlineOrder.id));
      expect(tokenizedOrder.tokenNumber, isNotNull);
      expect(tokenizedOrder.tokenNumber, startsWith('T-'));
      expect(tokenizedOrder.hasToken, isTrue);
      expect(tokenizedOrder.paymentStatus, equals('paid'));
      expect(tokenizedOrder.isPaid, isTrue);

      // Order enters the kitchen queue
      expect(tokenizedOrder.status, equals('pending'));
      expect(tokenizedOrder.queuePosition, isNotNull);
      expect(tokenizedOrder.queuePosition, isPositive);
      expect(tokenizedOrder.estimatedPrepTime, isNotEmpty);
    });

    testWidgets('CheckoutScreen allows toggling between Online and Offline Cash payment', (tester) async {
      final cart = CartProvider();
      cart.addToCart(const MenuItem(
        id: 'item-1',
        name: 'Veg Burger',
        price: 4.50,
        category: 'Fast Food',
        prepTime: '6 min',
        imageUrl: '',
      ));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<OrderProvider>(
              create: (_) => OrderProvider(orderService: orderService),
            ),
          ],
          child: const MaterialApp(
            home: CheckoutScreen(
              studentName: 'Test Student',
              studentEmail: 'student@campus.test',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check payment options are displayed
      expect(find.text('Payment Option'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Cash at Counter'), findsOneWidget);

      // Default is Online
      expect(find.text('Instant Token & Direct to Kitchen'), findsOneWidget);

      // Tap Cash at Counter
      await tester.tap(find.text('Cash at Counter'));
      await tester.pumpAndSettle();

      // Now Offline note should appear
      expect(find.text('Token Issued by Staff Upon Cash Payment'), findsOneWidget);
      expect(find.textContaining('Pay cash to staff at the counter to collect your token'), findsOneWidget);
    });

    testWidgets('OrderConfirmationScreen displays prominent token banners for online vs offline', (tester) async {
      // 1. Online Order with Auto-generated Token
      const onlineOrder = Order(
        id: 'ord-online-1',
        studentName: 'Aarav Patel',
        studentEmail: 'aarav@campus.test',
        items: [
          OrderItem(
            menuItemId: 'item-1',
            name: 'Cold Coffee',
            price: 2.50,
            quantity: 1,
            subtotal: 2.50,
          )
        ],
        totalAmount: 2.50,
        orderType: 'takeaway',
        status: 'pending',
        paymentMethod: 'online',
        paymentStatus: 'paid',
        tokenNumber: 'T-108',
        estimatedPrepTime: '11 min',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: OrderConfirmationScreen(order: onlineOrder),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Token is prominently displayed
      expect(find.text('TOKEN: #T-108'), findsOneWidget);
      expect(find.text('Online (Paid)'), findsOneWidget);

      // 2. Offline Order Awaiting Counter Cash Payment
      const offlineOrder = Order(
        id: 'ord-offline-2',
        studentName: 'Priya Sharma',
        studentEmail: 'priya@campus.test',
        items: [
          OrderItem(
            menuItemId: 'item-2',
            name: 'Grilled Sandwich',
            price: 3.50,
            quantity: 1,
            subtotal: 3.50,
          )
        ],
        totalAmount: 3.50,
        orderType: 'dine-in',
        status: 'awaiting_payment',
        paymentMethod: 'offline',
        paymentStatus: 'pending_payment',
        tokenNumber: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: OrderConfirmationScreen(order: offlineOrder),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TOKEN PENDING AT COUNTER'), findsOneWidget);
      expect(find.textContaining('Head to the counter, pay cash to the staff member'), findsOneWidget);
      expect(find.text('Cash at Counter (Unpaid)'), findsOneWidget);
    });
  });
}
