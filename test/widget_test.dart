// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:youthx/main.dart';

void main() {
  testWidgets('app loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const YouthXApp());

    expect(find.byType(GetMaterialApp), findsOneWidget);
  });

  testWidgets('splash screen navigates to onboarding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const YouthXApp());

    await tester.tap(find.text('Get Started →'));
    await tester.pumpAndSettle();

    expect(find.text('Connect with your Community'), findsOneWidget);
  });
}
