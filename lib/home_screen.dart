import 'package:flutter/material.dart';

import 'auth_service.dart';

class CanteenMenuItem {
  const CanteenMenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.preparationTime,
    required this.icon,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String preparationTime;
  final IconData icon;
}

const menuItems = [
  CanteenMenuItem(
    id: 'veg-wrap',
    name: 'Veggie Wrap',
    category: 'Meals',
    price: 4.50,
    preparationTime: '8 min',
    icon: Icons.wrap_text,
  ),
  CanteenMenuItem(
    id: 'chicken-rice',
    name: 'Chicken Rice Bowl',
    category: 'Meals',
    price: 6.75,
    preparationTime: '12 min',
    icon: Icons.rice_bowl,
  ),
  CanteenMenuItem(
    id: 'paneer-sandwich',
    name: 'Paneer Sandwich',
    category: 'Snacks',
    price: 3.80,
    preparationTime: '6 min',
    icon: Icons.breakfast_dining,
  ),
  CanteenMenuItem(
    id: 'samosa',
    name: 'Crispy Samosa',
    category: 'Snacks',
    price: 1.25,
    preparationTime: '4 min',
    icon: Icons.bakery_dining,
  ),
  CanteenMenuItem(
    id: 'cold-coffee',
    name: 'Cold Coffee',
    category: 'Drinks',
    price: 2.50,
    preparationTime: '3 min',
    icon: Icons.local_cafe,
  ),
  CanteenMenuItem(
    id: 'lemonade',
    name: 'Fresh Lemonade',
    category: 'Drinks',
    price: 1.80,
    preparationTime: '2 min',
    icon: Icons.local_drink,
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final AuthUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, int> _cart = {};
  String _selectedCategory = 'All';

  List<CanteenMenuItem> get _visibleItems => menuItems
      .where((item) => _selectedCategory == 'All' || item.category == _selectedCategory)
      .toList();

  int get _itemCount => _cart.values.fold(0, (total, quantity) => total + quantity);

  double get _total => menuItems.fold(
        0,
        (total, item) => total + item.price * (_cart[item.id] ?? 0),
      );

  void _addToCart(CanteenMenuItem item) {
    setState(() => _cart.update(item.id, (quantity) => quantity + 1, ifAbsent: () => 1));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to cart')),
    );
  }

  void _changeQuantity(CanteenMenuItem item, int change) {
    setState(() {
      final updatedQuantity = (_cart[item.id] ?? 0) + change;
      if (updatedQuantity <= 0) {
        _cart.remove(item.id);
      } else {
        _cart[item.id] = updatedQuantity;
      }
    });
  }

  void _showCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _cart.isEmpty
              ? const SizedBox(
                  height: 180,
                  child: Center(child: Text('Your cart is empty. Add something delicious!')),
                )
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Text('Your cart', style: Theme.of(context).textTheme.headlineSmall),
                    const Spacer(),
                    Text('$_itemCount items'),
                  ]),
                  const SizedBox(height: 16),
                  ...menuItems.where((item) => _cart.containsKey(item.id)).map((item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        subtitle: Text('\$${item.price.toStringAsFixed(2)} each'),
                        leading: IconButton(
                          tooltip: 'Remove one ${item.name}',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _changeQuantity(item, -1),
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('${_cart[item.id]}'),
                          IconButton(
                            tooltip: 'Add one ${item.name}',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _changeQuantity(item, 1),
                          ),
                        ]),
                      )),
                  const Divider(),
                  Row(children: [
                    Text('Total', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    Text('\$${_total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                  ]),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Choose pickup time'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const categories = ['All', 'Meals', 'Snacks', 'Drinks'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Canteen'),
        actions: [
          IconButton(
            tooltip: 'View cart',
            onPressed: _showCart,
            icon: CartIcon(itemCount: _itemCount),
          ),
        ],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text('Hi, ${widget.user.name}', style: Theme.of(context).textTheme.headlineSmall),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('What would you like to order today?'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ChoiceChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (_) => setState(() => _selectedCategory = category),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 210,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _visibleItems.length,
            itemBuilder: (context, index) {
              final item = _visibleItems[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(child: Icon(item.icon)),
                    const Spacer(),
                    Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${item.category} · ${item.preparationTime}'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text('\$${item.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      IconButton.filled(
                        tooltip: 'Add ${item.name}',
                        onPressed: () => _addToCart(item),
                        icon: const Icon(Icons.add),
                      ),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
      floatingActionButton: _itemCount == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: _showCart,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('View cart ($_itemCount)'),
            ),
    );
  }
}

class CartIcon extends StatelessWidget {
  const CartIcon({super.key, required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_bag_outlined),
          if (itemCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: CircleAvatar(
                radius: 9,
                child: Text(
                  '$itemCount',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
        ],
      );
}
