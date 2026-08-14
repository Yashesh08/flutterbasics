import 'package:course_system_crud/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows seeded courses and opens create form', (tester) async {
    await tester.pumpWidget(const CourseSystemApp());

    expect(find.text('Course System'), findsOneWidget);
    expect(find.text('Flutter Basics'), findsOneWidget);
    expect(find.text('Dart for Beginners'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Course'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });
}
