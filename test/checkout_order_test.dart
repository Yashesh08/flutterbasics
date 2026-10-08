import 'package:course_system_crud/models/menu_item.dart';
import 'package:course_system_crud/models/order.dart';
import 'package:course_system_crud/providers/cart_provider.dart';
import 'package:course_system_crud/providers/order_provider.dart';
import 'package:course_system_crud/screens/checkout_screen.dart';
import 'package:course_system_crud/screens/order_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  const sampleItem1 = MenuItem(
    id: 'item-1',
    name: 'Veggie Wrap',
    category: 'Meals',
    price: 4.50,
    prepTime: '8 min',
    imageUrl: '',
  );

  const sampleItem2 = MenuItem(
    id: 'item-2',
    name: 'Chicken Rice Bowl',
    category: 'Meals',
    price: 6.75,
    prepTime: '12 min',
    imageUrl: '',
  );

  testWidgets('Checkout screen displays dining option selector and calculated ETA preview', (tester) async {
    final cart = CartProvider();
    cart.addToCart(sampleItem1);
    cart.addToCart(sampleItem2);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
        ],
        child: const MaterialApp(
          home: CheckoutScreen(
            studentName: 'Asha Patel',
            studentEmail: 'student@campus.test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dine-In and Takeaway choices exist
    expect(find.text('Dining Option'), findsOneWidget);
    expect(find.text('Dine-In'), findsOneWidget);
    expect(find.text('Takeaway'), findsOneWidget);

    // Verify ETA calculation: MAX(8, 12) + 3 = 15 min preview
    expect(find.text('Estimated Ready Time: ~15 min'), findsOneWidget);

    // Switch to Takeaway
    await tester.tap(find.text('Takeaway'));
    await tester.pumpAndSettle();

    // Verify total amount is shown and Place Order button exists
    expect(find.text('₹11.25'), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Place Order'), findsOneWidget);
  });

  testWidgets('Order confirmation screen displays Order ID, Dining Option, and Ready By time', (tester) async {
    final now = DateTime.now();
    final readyAt = now.add(const Duration(minutes: 15));

    final confirmedOrder = Order(
      id: '6ac3d392816814c07cbeb48f',
      studentName: 'Asha Patel',
      studentEmail: 'student@campus.test',
      items: const [
        OrderItem(
          menuItemId: 'item-1',
          name: 'Veggie Wrap',
          price: 4.50,
          quantity: 1,
          subtotal: 4.50,
          prepTime: '8 min',
        ),
      ],
      totalAmount: 4.50,
      orderType: 'takeaway',
      status: 'pending',
      estimatedPrepTime: '11 min',
      expectedReadyAt: readyAt,
      createdAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrderConfirmationScreen(order: confirmedOrder),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order Confirmed'), findsOneWidget);
    expect(find.text('Dining Option'), findsOneWidget);
    expect(find.text('Takeaway'), findsOneWidget);
    expect(find.text('Ready By'), findsOneWidget);
    expect(find.text('11 min'), findsOneWidget);
    expect(find.text('#7cbeb48f'), findsOneWidget);
  });
}
