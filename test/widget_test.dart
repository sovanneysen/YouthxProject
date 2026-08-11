import 'package:flutter_test/flutter_test.dart';

import 'package:youthx_app/main.dart';

void main() {
  testWidgets('App boots to the Community feed', (WidgetTester tester) async {
    await tester.pumpWidget(const YouthXApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Community'), findsWidgets);
  });
}
