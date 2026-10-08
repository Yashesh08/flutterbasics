import 'package:course_system_crud/auth_service.dart';
import 'package:course_system_crud/home_screen.dart';
import 'package:course_system_crud/main.dart';
import 'package:course_system_crud/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('login screen opens the signup screen', (tester) async {
    await tester.pumpWidget(const CanteenApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Demo accounts'), findsOneWidget);

    final demoAccountFinder = find.text('student: student@campus.test / student123');
    await tester.ensureVisible(demoAccountFinder);
    await tester.tap(demoAccountFinder);
    await tester.pump();
    expect(find.text('student@campus.test'), findsOneWidget);

    final signupBtnFinder = find.text('New here? Create an account');
    await tester.ensureVisible(signupBtnFinder);
    await tester.tap(signupBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('seed student account logs in without a database', (tester) async {
    await tester.pumpWidget(const CanteenApp());

    final demoAccountFinder = find.text('student: student@campus.test / student123');
    await tester.ensureVisible(demoAccountFinder);
    await tester.tap(demoAccountFinder);

    final loginBtnFinder = find.widgetWithText(SubmitButton, 'Log in');
    await tester.ensureVisible(loginBtnFinder);
    await tester.tap(loginBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Asha Patel'), findsOneWidget);
    expect(find.text('Veggie Wrap'), findsOneWidget);
  });

  testWidgets('signup validates required fields before calling the API', (tester) async {
    await tester.pumpWidget(const CanteenApp());
    final signupBtnFinder = find.text('New here? Create an account');
    await tester.ensureVisible(signupBtnFinder);
    await tester.tap(signupBtnFinder);
    await tester.pumpAndSettle();

    final createBtnFinder = find.widgetWithText(SubmitButton, 'Create account');
    await tester.ensureVisible(createBtnFinder);
    await tester.tap(createBtnFinder);
    await tester.pump();

    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('home menu filters items and adds an item to the cart', (tester) async {
    const user = AuthUser(
      id: 'student-1',
      name: 'Asha',
      email: 'asha@example.com',
      role: 'student',
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: const MaterialApp(home: HomeScreen(user: user)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Veggie Wrap'), findsOneWidget);
    expect(find.text('Chicken Rice Bowl'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Veggie Wrap'));
    await tester.pump();

    expect(find.text('View Cart (1) · ₹4.50'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Drinks'));
    await tester.pumpAndSettle();

    expect(find.text('Cold Coffee'), findsOneWidget);
    expect(find.text('Veggie Wrap'), findsNothing);
  });
}
