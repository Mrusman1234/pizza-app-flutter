// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_multi_restaurant/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Fixed: Changed PizzaApp() to MyApp() to match main.dart
    await tester.pumpWidget(const MyApp());

    // Verify that our splash screen text is present.
    expect(find.text('Pizza O Clock'), findsOneWidget);
    expect(find.text('VEHARI'), findsOneWidget);
  });
}
