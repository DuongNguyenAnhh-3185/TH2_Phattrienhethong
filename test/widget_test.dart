import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:drift/native.dart';
import 'package:document_manager/database/database.dart';
import 'package:document_manager/state/document_provider.dart';
import 'package:document_manager/state/subject_provider.dart';
import 'package:document_manager/views/home/home_page.dart';

void main() {
  testWidgets('Kiểm thử giao diện HomePage tải dữ liệu độc lập với tầng lưu trữ',
      (WidgetTester tester) async {
    // 1. Khởi tạo In-Memory Database phục vụ việc kiểm thử giao diện
    final inMemoryDb = AppDatabase(NativeDatabase.memory());

    // 2. Bọc HomePage trong MultiProvider với In-Memory Database
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: inMemoryDb),
          ChangeNotifierProvider<DocumentProvider>(
            create: (_) => DocumentProvider(inMemoryDb),
          ),
          ChangeNotifierProvider<SubjectProvider>(
            create: (_) => SubjectProvider(inMemoryDb),
          ),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    // Chờ stream dữ liệu phát ra và giao diện re-render
    await tester.pumpAndSettle();

    // 3. Kiểm chứng các thành phần cốt lõi của giao diện hiển thị đúng
    expect(find.text('Cashew Docs'), findsOneWidget);
    expect(find.text('Kho Tài Liệu Học Tập'), findsOneWidget);
    expect(find.text('Tất cả môn'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Dọn dẹp tài nguyên
    await inMemoryDb.close();
  });
}
