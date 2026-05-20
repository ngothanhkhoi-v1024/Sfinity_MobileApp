import 'package:flutter_test/flutter_test.dart';

import 'package:sfinity/app.dart';

void main() {
  testWidgets('App loads home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const SfinityApp());
    expect(find.text('Trang chủ'), findsOneWidget);
  });
}
