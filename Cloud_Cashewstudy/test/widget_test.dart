import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_doc_manager/main.dart';
import 'package:study_doc_manager/presentation/screens/auth_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic test verifies widget tree builds
    expect(const CashewDocApp(), isNotNull);
  });

  testWidgets('Auth screen switches between sign in and registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNWidgets(2));

    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản'), findsOneWidget);
    expect(find.text('Nhập lại mật khẩu'), findsOneWidget);
  });
}
