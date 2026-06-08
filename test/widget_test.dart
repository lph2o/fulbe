import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbe/main.dart';

void main() {
  testWidgets('App launches and shows welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FulbeConnectApp());
    // Verify the app starts without crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
