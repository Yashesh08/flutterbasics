import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_item_row.dart';
import '../widgets/order_status_tracker.dart';
import 'order_confirmation_screen.dart';

/// Checkout screen where students review their cart, select dining option,
/// preview kitchen queue & ETA, select payment method, add instructions, and place order.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    this.studentName = 'Student',
    this.studentEmail = 'student@campus.edu',
  });

  final String studentName;
  final String studentEmail;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _instructionsController = TextEditingController();
  String _orderType = 'dine-in';
  String _paymentMethod = 'online';
  bool _placingOrder = false;

  final List<String> _quickNotes = [
    'Less spicy',
    'Extra sauce / chutney',
    'No onions',
    'Serve extra hot',
    'Pack cutlery',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQueueStatus();
    });
  }

  void _loadQueueStatus() {
    final cart = context.read<CartProvider>();
    final maxPrep = cart.items.fold<int>(8, (max, ci) {
      final match = RegExp(r'\d+').firstMatch(ci.item.prepTime);
      final val = match != null ? int.parse(match.group(0)!) : 8;
      return val > max ? val : max;
    });
    context.read<OrderProvider>().fetchQueueEstimate(itemPrepMinutes: maxPrep);
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (cart.isEmpty) return;

    setState(() => _placingOrder = true);

    try {
      final items = cart.items
          .map((ci) => {
                'menuItemId': ci.item.id,
                'id': ci.item.id,
                'name': ci.item.name,
                'price': ci.item.price,
                'quantity': ci.quantity,
                'prepTime': ci.item.prepTime,
              })
          .toList();

      final order = await orderProvider.placeOrder(
        studentName: widget.studentName,
        studentEmail: widget.studentEmail,
        items: items,
        totalAmount: cart.totalAmount,
        orderType: _orderType,
        paymentMethod: _paymentMethod,
        specialInstructions: _instructionsController.text.trim(),
      );

      if (!mounted) return;

      // Clear cart after successful order
      cart.clearCart();

      // Navigate to confirmation screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            order: order,
            studentEmail: widget.studentEmail,
            studentName: widget.studentName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: colorScheme.outline.withAlpha(120),
                  ),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Menu'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: Student Profile Card
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withAlpha(80),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Icon(Icons.person, color: colorScheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.studentName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        widget.studentEmail,
                                        style: TextStyle(
                                          color: colorScheme.outline,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // SECTION 2: Dining Option
                        Text(
                          'Dining Option',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'dine-in',
                              label: Text('Dine-In'),
                              icon: Icon(Icons.restaurant),
                            ),
                            ButtonSegment(
                              value: 'takeaway',
                              label: Text('Takeaway'),
                              icon: Icon(Icons.takeout_dining),
                            ),
                          ],
                          selected: {_orderType},
                          onSelectionChanged: (set) =>
                              setState(() => _orderType = set.first),
                        ),
                        const SizedBox(height: 18),

                        // SECTION 3: Payment Option
                        Text(
                          'Payment Option',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'online',
                              label: Text('Online'),
                              icon: Icon(Icons.payment),
                            ),
                            ButtonSegment(
                              value: 'offline',
                              label: Text('Cash at Counter'),
                              icon: Icon(Icons.point_of_sale),
                            ),
                          ],
                          selected: {_paymentMethod},
                          onSelectionChanged: (set) =>
                              setState(() => _paymentMethod = set.first),
                        ),
                        const SizedBox(height: 10),

                        // Payment Guidance Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'online'
                                ? Colors.green.shade50
                                : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'online'
                                  ? Colors.green.shade200
                                  : Colors.amber.shade300,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _paymentMethod == 'online'
                                    ? Icons.bolt
                                    : Icons.storefront,
                                color: _paymentMethod == 'online'
                                    ? Colors.green.shade800
                                    : Colors.amber.shade900,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _paymentMethod == 'online'
                                          ? 'Instant Token & Direct to Kitchen'
                                          : 'Token Issued by Staff Upon Cash Payment',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: _paymentMethod == 'online'
                                            ? Colors.green.shade900
                                            : Colors.amber.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _paymentMethod == 'online'
                                          ? 'Your token number will be generated immediately and sent to the cooking queue.'
                                          : 'Pay cash to staff at the counter to collect your token and enter the cooking queue.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _paymentMethod == 'online'
                                            ? Colors.green.shade900
                                            : Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // SECTION 4: Kitchen Queue & ETA Card
                        Text(
                          'Kitchen Wait Time & ETA',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<OrderProvider>(
                          builder: (context, orderProvider, _) {
                            final maxPrep = cart.items.fold<int>(5, (max, ci) {
                              final match = RegExp(r'\d+').firstMatch(ci.item.prepTime);
                              final val = match != null ? int.parse(match.group(0)!) : 5;
                              return val > max ? val : max;
                            });

                            final queueEstimate = orderProvider.queueEstimate;
                            final ordersInQueue =
                                (queueEstimate?['ordersInQueue'] as num?)?.toInt() ?? 0;
                            final queueWaitMinutes =
                                (queueEstimate?['queueWaitMinutes'] as num?)?.toInt() ?? 0;
                            final queuePosition =
                                (queueEstimate?['queuePosition'] as num?)?.toInt() ??
                                    (ordersInQueue + 1);
                            final previewEta = maxPrep + queueWaitMinutes + 3;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colorScheme.primary.withAlpha(60),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(Icons.soup_kitchen_outlined,
                                        color: colorScheme.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Estimated Ready Time: ~$previewEta min',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Queue #$queuePosition',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ordersInQueue == 0
                                              ? 'Kitchen is free (0 in queue). Food: ~$maxPrep min + 3 min buffer.'
                                              : 'Kitchen Queue: $ordersInQueue order${ordersInQueue > 1 ? 's' : ''} ahead (~$queueWaitMinutes min queue wait + ~$maxPrep min food prep + 3 min buffer).',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),

                        // SECTION 5: Order Items Breakdown
                        Text(
                          '4. Order Summary (${cart.itemCount} items)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withAlpha(60),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                ...cart.items.map((ci) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: OrderItemRow(
                                        name: ci.item.name,
                                        quantity: ci.quantity,
                                        price: ci.item.price,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // SECTION 6: Special Instructions
                        Text(
                          '5. Special Instructions (Optional)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: _quickNotes.map((note) {
                            return ActionChip(
                              label: Text(note, style: const TextStyle(fontSize: 11)),
                              onPressed: () {
                                final current = _instructionsController.text.trim();
                                if (current.isEmpty) {
                                  _instructionsController.text = note;
                                } else if (!current.contains(note)) {
                                  _instructionsController.text = '$current, $note';
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _instructionsController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'E.g., No onions, extra spicy, sauce on the side...',
                            hintStyle: TextStyle(
                              color: colorScheme.outline.withAlpha(160),
                              fontSize: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // SECTION 7: Order Progress Preview Tracker
                        const OrderStatusTracker(status: 'pending', compact: false),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom Checkout Summary & Prominent CTA
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Items Total'),
                            Text(
                              '₹${cart.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Payable',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${cart.totalAmount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _placingOrder ? null : _placeOrder,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _placingOrder
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Place Order',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      ' • ₹${cart.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
