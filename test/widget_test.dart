import 'package:flutter_test/flutter_test.dart';
import 'package:derby2_flutter/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const Derby2App());
    expect(find.text('Derby Manager'), findsOneWidget);
  });
}
