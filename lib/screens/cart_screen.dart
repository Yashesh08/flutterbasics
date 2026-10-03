import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Cart',
              onPressed: () => _confirmClearCart(context, cart),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 96,
                    color: Theme.of(context).colorScheme.outline.withAlpha(120),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Discover something delicious from the canteen menu!'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Browse Menu'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final cartItem = cart.items[index];
                      final item = cartItem.item;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Avatar / Icon
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(
                                    item.categoryIcon,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Item details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '\$${item.price.toStringAsFixed(2)} each · ${item.prepTime}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Subtotal: \$${cartItem.totalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => cart.decrementQuantity(item.id),
                                    ),
                                    Text(
                                      '${cartItem.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => cart.addToCart(item),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Order Summary Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
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
                            Text('\$${cart.totalAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Prep Time',
                              style: TextStyle(color: Theme.of(context).colorScheme.outline),
                            ),
                            Text(
                              _calculateEstimatedPrepTime(cart),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '\$${cart.totalAmount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Checkout screen will be integrated in Day 3 module!'),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Proceed to Checkout (${cart.itemCount} items)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  String _calculateEstimatedPrepTime(CartProvider cart) {
    if (cart.isEmpty) return '0 min';
    int maxPrep = 0;
    for (final item in cart.items) {
      final text = item.item.prepTime.replaceAll(RegExp(r'[^0-9]'), '');
      final time = int.tryParse(text) ?? 5;
      if (time > maxPrep) maxPrep = time;
    }
    return '${maxPrep + 3} min';
  }

  void _confirmClearCart(BuildContext context, CartProvider cart) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
