import 'package:flutter/material.dart';

/// Reusable widget for displaying an individual order item row with quantity, name, and subtotal.
class OrderItemRow extends StatelessWidget {
  const OrderItemRow({
    super.key,
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final double price;

  @override
  Widget build(BuildContext context) {
    final subtotal = quantity * price;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${quantity}x  $name',
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '₹${subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
