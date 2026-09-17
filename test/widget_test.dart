import 'package:course_system_crud/auth_service.dart';
import 'package:course_system_crud/home_screen.dart';
import 'package:course_system_crud/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login screen opens the signup screen', (tester) async {
    await tester.pumpWidget(const CanteenApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Demo accounts'), findsOneWidget);

    await tester.tap(find.text('student: student@campus.test / student123'));
    await tester.pump();
    expect(find.text('student@campus.test'), findsOneWidget);

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('seed student account logs in without a database', (tester) async {
    await tester.pumpWidget(const CanteenApp());

    await tester.tap(find.text('student: student@campus.test / student123'));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Asha Patel'), findsOneWidget);
    expect(find.text('Veggie Wrap'), findsOneWidget);
  });

  testWidgets('signup validates required fields before calling the API', (tester) async {
    await tester.pumpWidget(const CanteenApp());
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
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
    await tester.pumpWidget(const MaterialApp(home: HomeScreen(user: user)));

    expect(find.text('Veggie Wrap'), findsOneWidget);
    expect(find.text('Chicken Rice Bowl'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Veggie Wrap'));
    await tester.pump();

    expect(find.text('View cart (1)'), findsOneWidget);

    await tester.tap(find.text('Drinks'));
    await tester.pump();

    expect(find.text('Cold Coffee'), findsOneWidget);
    expect(find.text('Veggie Wrap'), findsNothing);
  });
}
