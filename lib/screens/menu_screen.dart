import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_provider.dart';
import '../services/menu_service.dart';
import '../widgets/menu_item_card.dart';
import 'admin_dashboard_screen.dart';
import 'admin_menu_management_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    this.user,
    this.userName,
    this.userEmail,
    this.menuService,
  });

  final AuthUser? user;
  final String? userName;
  final String? userEmail;
  final MenuService? menuService;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final MenuService _menuService;
  final TextEditingController _searchController = TextEditingController();
  List<MenuItem> _allMenuItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String? _selectedMood;

  final List<String> _categories = [
    'All',
    'Meals',
    'Snacks',
    'Beverages',
    'Drinks',
    'Desserts',
  ];

  static const List<Map<String, dynamic>> _moodFilters = [
    {
      'id': 'quick_bite',
      'label': 'Quick Bite',
      'icon': Icons.bolt,
    },
    {
      'id': 'sweet',
      'label': 'Something Sweet',
      'icon': Icons.cake_outlined,
    },
    {
      'id': 'drinks',
      'label': 'Drinks',
      'icon': Icons.local_cafe_outlined,
    },
    {
      'id': 'proper_meal',
      'label': 'Proper Meal',
      'icon': Icons.lunch_dining_outlined,
    },
    {
      'id': 'under_100',
      'label': 'Under ₹100',
      'icon': Icons.savings_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _menuService = widget.menuService ?? MenuService();
    _loadMenuData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  List<MenuItem> _applyFilters(List<MenuItem> items) {
    return items.where((item) {
      // Category filter
      final matchesCategory = _selectedCategory == 'All' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();

      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());

      // Mood filter
      bool matchesMood = true;
      if (_selectedMood != null) {
        switch (_selectedMood) {
          case 'quick_bite':
            matchesMood = item.isQuickBite;
            break;
          case 'sweet':
            matchesMood = item.isSweet;
            break;
          case 'drinks':
            matchesMood = item.isDrink;
            break;
          case 'proper_meal':
            matchesMood = item.isProperMeal;
            break;
          case 'under_100':
            matchesMood = item.isUnder100;
            break;
        }
      }

      return matchesCategory && matchesSearch && matchesMood;
    }).toList();
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = 'All';
      _selectedMood = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final menuProvider = context.watch<MenuProvider?>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sourceList = (menuProvider != null && menuProvider.items.isNotEmpty)
        ? menuProvider.items
        : _allMenuItems;

    final filteredItems = _applyFilters(sourceList);
    final isFiltering = _searchQuery.isNotEmpty ||
        _selectedCategory != 'All' ||
        _selectedMood != null;

    final popularItems = sourceList.where((i) => i.isPopular && i.available).toList();
    final recommendedItems = sourceList
        .where((i) => !popularItems.contains(i) && i.available)
        .toList();

    final displayName = widget.user?.name ?? widget.userName ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restaurant, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Campus Canteen',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  widget.userName != null
                      ? 'Welcome, ${widget.userName}'
                      : (widget.user?.name != null
                          ? 'Welcome, ${widget.user!.name}'
                          : 'Fresh & Fast Food'),
                  style: TextStyle(fontSize: 11, color: colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.user?.role == 'staff' || widget.user?.role == 'admin') ...[
            IconButton(
              tooltip: 'Manage Menu (Admin CRUD)',
              icon: const Icon(Icons.restaurant_menu),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminMenuManagementScreen(),
                  ),
                );
                _loadMenuData();
              },
            ),
            IconButton(
              tooltip: 'Admin Dashboard',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => OrderProvider(),
                      child: AdminDashboardScreen(staffUser: widget.user),
                    ),
                  ),
                );
                _loadMenuData();
              },
            ),
          ],
          IconButton(
            tooltip: 'My Orders',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyOrdersScreen(
                    studentEmail: widget.user?.email ??
                        widget.userEmail ??
                        'student@campus.test',
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'View Cart',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CartScreen(
                    studentName: widget.user?.name ?? widget.userName ?? 'Student',
                    studentEmail: widget.user?.email ??
                        widget.userEmail ??
                        'student@campus.test',
                  ),
                ),
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
      body: _isLoading
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
              : RefreshIndicator(
                  onRefresh: _loadMenuData,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 90),
                    children: [
                      // Greeting & Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()}, $displayName 👋',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'What are you craving today?',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Prominent Search Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search food, snacks, drinks...',
                              hintStyle: TextStyle(
                                color: colorScheme.outline.withAlpha(160),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: colorScheme.primary,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: colorScheme.outlineVariant.withAlpha(100),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: colorScheme.outlineVariant.withAlpha(100),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // "What are you in the mood for?" Quick Filters
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          'What are you in the mood for?',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _moodFilters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final filter = _moodFilters[index];
                            final isSelected = _selectedMood == filter['id'];
                            return FilterChip(
                              avatar: Icon(
                                filter['icon'] as IconData,
                                size: 16,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.primary,
                              ),
                              label: Text(filter['label'] as String),
                              selected: isSelected,
                              selectedColor: colorScheme.primary,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                              ),
                              backgroundColor: colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant.withAlpha(120),
                                ),
                              ),
                              showCheckmark: false,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedMood =
                                      selected ? filter['id'] as String : null;
                                });
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Food Categories Filter Row
                      SizedBox(
                        height: 42,
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
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Main Content Area: Filtered results OR Multi-Section Discovery Feed
                      if (isFiltering) ...[
                        // Filter header banner
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Results (${filteredItems.length})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _clearAllFilters,
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Clear Filters'),
                              ),
                            ],
                          ),
                        ),
                        if (filteredItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(Icons.search_off,
                                    size: 56,
                                    color: colorScheme.outline.withAlpha(120)),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No items matching "$_searchQuery"'
                                      : 'No items match your filter criteria.',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _clearAllFilters,
                                  child: const Text('Show All Items'),
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisExtent: 250,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                return MenuItemCard(
                                  item: filteredItems[index],
                                  allItems: sourceList,
                                );
                              },
                            ),
                          ),
                      ] else ...[
                        // SECTION 1: 🔥 Popular / Canteen Favorites (Horizontal)
                        if (popularItems.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                            child: Row(
                              children: [
                                const Text(
                                  '🔥 Popular / Canteen Favorites',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${popularItems.length} items',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 250,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: popularItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return MenuItemCard(
                                  item: popularItems[index],
                                  allItems: sourceList,
                                  isCompactHorizontal: true,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // SECTION 2: ✨ Recommended for You (Horizontal)
                        if (recommendedItems.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: Row(
                              children: [
                                const Text(
                                  '✨ Recommended for You',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Chef\'s pick',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 250,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: recommendedItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return MenuItemCard(
                                  item: recommendedItems[index],
                                  allItems: sourceList,
                                  isCompactHorizontal: true,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // SECTION 3: 🍽️ All Menu Items (Grid)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              const Text(
                                '🍽️ Explore Full Menu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${sourceList.length} items',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisExtent: 250,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: sourceList.length,
                            itemBuilder: (context, index) {
                              return MenuItemCard(
                                item: sourceList[index],
                                allItems: sourceList,
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      floatingActionButton: cart.itemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CartScreen(
                      studentName:
                          widget.user?.name ?? widget.userName ?? 'Student',
                      studentEmail: widget.user?.email ??
                          widget.userEmail ??
                          'student@campus.test',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_bag),
              label: Text(
                'View Cart (${cart.itemCount}) · ₹${cart.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
