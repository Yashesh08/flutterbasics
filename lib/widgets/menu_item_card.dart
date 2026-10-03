import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final quantityInCart = cart.getQuantity(item.id);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Thumbnail
          Stack(
            children: [
              Container(
                height: 90,
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                      )
                    : _buildPlaceholder(context),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 11, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        item.prepTime,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              if (!item.available)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withAlpha(140),
                    child: const Center(
                      child: Text(
                        'Sold Out',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (quantityInCart > 0)
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => cart.decrementQuantity(item.id),
                                borderRadius: BorderRadius.circular(16),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.remove, size: 14),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '$quantityInCart',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              InkWell(
                                onTap: () => cart.addToCart(item),
                                borderRadius: BorderRadius.circular(16),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.add, size: 14),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          onPressed: item.available
                              ? () {
                                  cart.addToCart(item);
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${item.name} added to cart'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          tooltip: 'Add ${item.name}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        item.categoryIcon,
        size: 36,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
