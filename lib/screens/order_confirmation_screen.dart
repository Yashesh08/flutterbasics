import 'package:flutter/material.dart';
import '../models/order.dart';
import '../widgets/order_status_tracker.dart';
import 'my_orders_screen.dart';

/// Screen shown after an order is successfully placed.
/// Shows order token, visual status tracker, items summary, ETA, and quick actions.
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
        title: const Text('Order Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Success Icon
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Order Placed Successfully!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              order.isOnlinePayment
                  ? 'Your payment was confirmed and your token is generated.'
                  : 'Order submitted! Please collect your token at the counter.',
              style: TextStyle(color: colorScheme.outline, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Token & Payment Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: order.hasToken
                    ? Colors.green.shade50
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: order.hasToken
                      ? Colors.green.shade300
                      : Colors.amber.shade400,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        order.hasToken
                            ? Icons.confirmation_number
                            : Icons.point_of_sale,
                        color: order.hasToken
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.hasToken
                            ? 'TOKEN: #${order.tokenNumber}'
                            : 'TOKEN PENDING AT COUNTER',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: order.hasToken
                              ? Colors.green.shade900
                              : Colors.amber.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.hasToken
                        ? 'Token generated automatically. Your order is now in the kitchen queue!'
                        : 'Head to the counter, pay cash to the staff member, and collect your token to start cooking.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: order.hasToken
                          ? Colors.green.shade900
                          : Colors.amber.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Status Lifecycle Tracker
            OrderStatusTracker(status: order.status, compact: false),
            const SizedBox(height: 16),

            // Order details card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(70),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(
                      context,
                      'Order Token',
                      order.tokenDisplay,
                      valueColor: order.hasToken
                          ? Colors.green.shade800
                          : Colors.amber.shade900,
                    ),
                    const Divider(height: 20),
                    _detailRow(
                      context,
                      'Payment Method',
                      order.isOnlinePayment
                          ? 'Online (Paid)'
                          : 'Cash at Counter (Unpaid)',
                      valueColor: order.isOnlinePayment
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                    ),
                    const Divider(height: 20),
                    _detailRow(
                      context,
                      'Order ID',
                      '#${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                    ),
                    const Divider(height: 20),
                    _detailRow(
                      context,
                      'Dining Option',
                      order.formattedOrderType,
                    ),
                    const Divider(height: 20),
                    _detailRow(
                      context,
                      'Kitchen Queue',
                      order.hasToken && order.queuePosition != null
                          ? 'Queue #${order.queuePosition} (${order.ordersAhead ?? 0} ahead)'
                          : 'Awaiting Token at Counter',
                      valueColor: colorScheme.primary,
                    ),
                    const Divider(height: 20),
                    _detailRow(context, 'Status', order.statusLabel,
                        valueColor: order.statusColor),
                    const Divider(height: 20),
                    _detailRow(
                      context,
                      'Estimated Prep',
                      order.estimatedPrepTime.isNotEmpty
                          ? order.estimatedPrepTime
                          : '~15 min',
                    ),
                    const Divider(height: 20),
                    _detailRow(
                      context,
                      'Ready By',
                      order.formattedReadyTime,
                      valueColor: Colors.green.shade700,
                    ),
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
                                '₹${item.subtotal.toStringAsFixed(2)}',
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
                          'Total Paid',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Back to menu button
            FilledButton.icon(
              onPressed: () {
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
