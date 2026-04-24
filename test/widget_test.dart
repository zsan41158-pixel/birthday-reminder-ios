import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_reminder_ios/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BirthdayReminderApp()),
    );

    expect(find.text('生日提醒'), findsOneWidget);
    expect(find.text('暂无家人信息'), findsOneWidget);
  });
}
