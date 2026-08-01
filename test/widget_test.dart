import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quiz_application_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuizApp());

    // আপনার অ্যাপের প্রথম স্ক্রিনে যে টেক্সট বা উইজেট থাকার কথা, 
    // সেটি এখানে ভেরিফাই করতে পারেন। যেমন অ্যাপের টাইটেল বা লগইন বাটন:
    await tester.pumpAndSettle();

    // উদাহরণস্বরূপ:
    // expect(find.byType(MaterialApp), findsOneWidget);
  });
}