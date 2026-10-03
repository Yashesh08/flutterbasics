import 'package:flutter/material.dart';
import '../models/order.dart';
import 'my_orders_screen.dart';

/// Screen shown after an order is successfully placed.
/// Shows order ID, status, items summary, and estimated prep time.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.order,
    this.studentEmail,
    this.studentName,
  });

  final Order order;
  final String? studentEmail;
  final String? studentName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Success Icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Order Placed!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been placed successfully.',
              style: TextStyle(color: colorScheme.outline, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Order details card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(context, 'Order ID', '#${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0)}'),
                    const Divider(height: 20),
                    _detailRow(context, 'Status', order.statusLabel,
                        valueColor: Colors.orange),
                    const Divider(height: 20),
                    _detailRow(context, 'Estimated Prep',
                        order.estimatedPrepTime.isNotEmpty ? order.estimatedPrepTime : '~15 min'),
                    const Divider(height: 20),
                    _detailRow(context, 'Items', '${order.items.length} item(s)'),
                    const Divider(height: 20),

                    // Item list
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}× ${item.name}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        )),

                    if (order.specialInstructions.isNotEmpty) ...[
                      const Divider(height: 20),
                      Text(
                        'Special Instructions',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.specialInstructions,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],

                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '\$${order.totalAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Back to menu button
            FilledButton.icon(
              onPressed: () {
                // Pop back to menu screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Back to Menu'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate directly to My Orders
                Navigator.of(context).popUntil((route) => route.isFirst);
                if (studentEmail != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MyOrdersScreen(
                        studentEmail: studentEmail!,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('View My Orders'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
