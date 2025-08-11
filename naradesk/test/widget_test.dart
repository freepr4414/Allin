// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naradesk/main.dart';

void main() {
  testWidgets('Study Cafe App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StudyCafeApp());

    // Verify that login screen is displayed initially.
    expect(find.text('스터디카페 관리 시스템'), findsOneWidget);
    expect(find.text('로그인'), findsWidgets);

    // Verify that username and password fields exist.
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
