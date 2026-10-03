import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../services/menu_service.dart';
import '../widgets/menu_item_card.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.userName, this.menuService});

  final String? userName;
  final MenuService? menuService;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final MenuService _menuService;
  List<MenuItem> _allMenuItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = ['All', 'Meals', 'Snacks','Beverages', 'Drinks', 'Desserts'];

  @override
  void initState() {
    super.initState();
    _menuService = widget.menuService ?? MenuService();
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _menuService.fetchMenuItems();
      if (!mounted) return;
      setState(() {
        _allMenuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load canteen menu items.';
        _isLoading = false;
      });
    }
  }

  List<MenuItem> get _filteredItems {
    return _allMenuItems.where((item) {
      final matchesCategory =
          _selectedCategory == 'All' || item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty || item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Campus Canteen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (widget.userName != null)
              Text(
                'Welcome, ${widget.userName}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View Cart',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: Badge(
              label: Text('${cart.itemCount}'),
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search food or drinks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Categories horizontal list
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Menu Grid / State View
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Fetching today\'s fresh menu...'),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadMenuData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : _filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No items matching "$_searchQuery"'
                                      : 'No menu items available in this category.',
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMenuData,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisExtent: 230,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                return MenuItemCard(item: _filteredItems[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: cart.itemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              icon: const Icon(Icons.shopping_bag),
              label: Text('View Cart (${cart.itemCount}) · \$${cart.totalAmount.toStringAsFixed(2)}'),
            )
          : null,
    );
  }
}
