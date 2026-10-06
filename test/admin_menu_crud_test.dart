import 'dart:convert';
import 'package:course_system_crud/auth_service.dart';
import 'package:course_system_crud/home_screen.dart';
import 'package:course_system_crud/models/menu_item.dart';
import 'package:course_system_crud/providers/cart_provider.dart';
import 'package:course_system_crud/providers/menu_provider.dart';
import 'package:course_system_crud/providers/order_provider.dart';
import 'package:course_system_crud/screens/add_edit_menu_item_screen.dart';
import 'package:course_system_crud/screens/admin_dashboard_screen.dart';
import 'package:course_system_crud/screens/admin_menu_management_screen.dart';
import 'package:course_system_crud/services/menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

MenuService createMockMenuService() {
  final items = <MenuItem>[
    const MenuItem(
      id: '6ac3b12bb30f61620c5b136d',
      name: 'Veggie Wrap',
      category: 'Meals',
      price: 4.50,
      prepTime: '8 min',
      imageUrl: '',
      available: true,
    ),
  ];

  final client = MockClient((request) async {
    final method = request.method;
    final path = request.url.path;

    if (method == 'GET' && path == '/api/menu') {
      return http.Response(jsonEncode(items.map((i) => i.toJson()).toList()), 200);
    }
    if (method == 'POST' && path == '/api/menu') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final created = MenuItem(
        id: '6ac3d1d7d193147e8c91adbc',
        name: body['name'] as String,
        category: body['category'] as String,
        price: (body['price'] as num).toDouble(),
        prepTime: body['prepTime'] as String,
        imageUrl: body['imageUrl'] as String? ?? '',
        available: body['available'] as bool? ?? true,
      );
      items.insert(0, created);
      return http.Response(jsonEncode(created.toJson()), 201);
    }
    if (method == 'PUT' && path.startsWith('/api/menu/')) {
      final id = path.replaceFirst('/api/menu/', '');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final index = items.indexWhere((i) => i.id == id);
      final updated = MenuItem(
        id: id,
        name: body['name'] as String? ?? (index != -1 ? items[index].name : ''),
        category: body['category'] as String? ?? (index != -1 ? items[index].category : 'Meals'),
        price: (body['price'] as num?)?.toDouble() ?? (index != -1 ? items[index].price : 0.0),
        prepTime: body['prepTime'] as String? ?? (index != -1 ? items[index].prepTime : '10 min'),
        imageUrl: body['imageUrl'] as String? ?? '',
        available: body['available'] as bool? ?? true,
      );
      if (index != -1) items[index] = updated;
      return http.Response(jsonEncode(updated.toJson()), 200);
    }
    if (method == 'DELETE' && path.startsWith('/api/menu/')) {
      final id = path.replaceFirst('/api/menu/', '');
      items.removeWhere((i) => i.id == id);
      return http.Response(jsonEncode({'message': 'Menu item deleted successfully.'}), 200);
    }
    return http.Response('Not found', 404);
  });

  return MenuService(client: client);
}

void main() {
  const staffUser = AuthUser(
    id: 'seed-staff-1',
    name: 'Ravi Kumar',
    email: 'staff@campus.test',
    role: 'staff',
  );

  const studentUser = AuthUser(
    id: 'seed-student-1',
    name: 'Asha Patel',
    email: 'student@campus.test',
    role: 'student',
  );

  Widget createTestApp({required Widget home, MenuProvider? menuProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(
          create: (_) => menuProvider ?? MenuProvider(menuService: createMockMenuService()),
        ),
      ],
      child: MaterialApp(
        home: home,
      ),
    );
  }

  testWidgets('Admin Dashboard displays NavigationBar with Menu CRUD tab', (tester) async {
    await tester.pumpWidget(createTestApp(
      home: const AdminDashboardScreen(staffUser: staffUser),
    ));
    await tester.pumpAndSettle();

    // Verify both tabs exist in bottom NavigationBar
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Menu CRUD'), findsOneWidget);

    // Switch to Menu CRUD tab
    await tester.tap(find.text('Menu CRUD'));
    await tester.pumpAndSettle();

    expect(find.text('Total Items'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Out of Stock'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
  });

  testWidgets('Add New Menu Item validates required fields', (tester) async {
    await tester.pumpWidget(createTestApp(
      home: const AddEditMenuItemScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Add New Menu Item'), findsOneWidget);

    // Tap Add Menu Item with empty form
    final submitButton = find.widgetWithText(FilledButton, 'Add Menu Item');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Validation errors should appear
    expect(find.text('Please enter item name.'), findsOneWidget);
    expect(find.text('Enter price'), findsOneWidget);
  });

  testWidgets('Admin can add a new menu item, edit it, and delete it', (tester) async {
    final menuProvider = MenuProvider(menuService: createMockMenuService());
    await menuProvider.loadMenu();

    await tester.pumpWidget(createTestApp(
      home: const AdminMenuManagementScreen(),
      menuProvider: menuProvider,
    ));
    await tester.pumpAndSettle();

    // Verify initial item exists
    expect(find.text('Veggie Wrap'), findsOneWidget);

    // Tap Add Item FAB
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Item'));
    await tester.pumpAndSettle();

    // Fill form for new item
    await tester.enterText(find.widgetWithText(TextFormField, 'Item Name *'), 'Special Samosa Chaat');
    await tester.enterText(find.widgetWithText(TextFormField, 'Price (\$) *'), '3.25');
    await tester.enterText(find.widgetWithText(TextFormField, 'Estimated Prep Time'), '5 min');

    // Submit form
    final saveButton = find.widgetWithText(FilledButton, 'Add Menu Item');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Screen should pop back and new item should appear in the list
    expect(find.text('Special Samosa Chaat'), findsOneWidget);
    expect(find.text('\$3.25'), findsOneWidget);

    // Edit the item
    final editButton = find.byTooltip('Edit item').first;
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.text('Edit Menu Item'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Price (\$) *'), '3.75');

    final updateButton = find.widgetWithText(FilledButton, 'Update Menu Item');
    await tester.ensureVisible(updateButton);
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    // Price should now be $3.75
    expect(find.text('\$3.75'), findsOneWidget);

    // Delete the item
    final deleteButton = find.byTooltip('Delete item').first;
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirmation dialog should appear
    expect(find.text('Delete Menu Item'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    // Item should no longer appear
    expect(find.text('Special Samosa Chaat'), findsNothing);
  });

  testWidgets('End-to-End Sync: Admin adds item -> item appears on Student Menu and can be added to Cart', (tester) async {
    final menuProvider = MenuProvider(menuService: createMockMenuService());
    await menuProvider.loadMenu();
    final cartProvider = CartProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cartProvider),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider.value(value: menuProvider),
        ],
        child: const MaterialApp(
          home: HomeScreen(user: studentUser),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Student starts on HomeScreen / MenuScreen
    expect(find.text('Veggie Wrap'), findsOneWidget);

    // Admin creates a new item in the shared MenuProvider
    await menuProvider.addItem(const MenuItem(
      id: 'fresh-dosa',
      name: 'Mysore Masala Dosa',
      category: 'Meals',
      price: 5.25,
      prepTime: '7 min',
      imageUrl: '',
      available: true,
    ));
    await tester.pumpAndSettle();

    // The new item is immediately visible on the student's MenuScreen!
    expect(find.text('Mysore Masala Dosa'), findsOneWidget);
    expect(find.text('\$5.25'), findsOneWidget);

    // Student can add the newly created item to the cart!
    final addToCartFinder = find.byTooltip('Add Mysore Masala Dosa');
    await tester.ensureVisible(addToCartFinder);
    await tester.tap(addToCartFinder);
    await tester.pumpAndSettle();

    // Cart shows 1 item with price $5.25
    expect(cartProvider.itemCount, 1);
    expect(cartProvider.totalAmount, 5.25);
    expect(find.text('View Cart (1) · \$5.25'), findsOneWidget);
  });
}
