import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:document_manager/database/database.dart';
import 'package:document_manager/models/document_type.dart';
import 'package:document_manager/models/document_filter.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Khởi tạo In-Memory SQLite Database độc lập hoàn toàn với file hệ thống
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Kiểm thử Tầng Dữ liệu & Nghiệp vụ (Drift SQLite DAO Tests)', () {
    test('1. Thêm mới và truy vấn Môn học (Subject CRUD)', () async {
      final initialSubjects = await db.subjectDao.getAllSubjects();
      final initialCount = initialSubjects.length; // Số lượng môn học mẫu đã seed ban đầu

      final subjectId = await db.subjectDao.insertSubject(
        SubjectsCompanion.insert(
          name: 'Lập trình Flutter Nâng cao',
          code: 'FLT101',
          colorValue: const Value(0xFF2563EB),
        ),
      );

      expect(subjectId, greaterThan(0));

      final subjects = await db.subjectDao.getAllSubjects();
      expect(subjects.length, initialCount + 1);
      final inserted = subjects.firstWhere((s) => s.id == subjectId);
      expect(inserted.name, 'Lập trình Flutter Nâng cao');
      expect(inserted.code, 'FLT101');
    });

    test('2. Thêm mới, cập nhật và xóa Tài liệu học tập (Document CRUD)', () async {
      // Chuẩn bị môn học
      final subjectId = await db.subjectDao.insertSubject(
        SubjectsCompanion.insert(
          name: 'Cấu trúc Dữ liệu',
          code: 'DSA202',
        ),
      );

      // Thêm tài liệu
      final docId = await db.documentDao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Bài tập 1: Cây tìm kiếm nhị phân BST',
          description: const Value('Cài đặt các phép toán thêm, xóa nút trên BST'),
          documentType: DocumentType.assignment,
          subjectId: subjectId,
          tags: const Value('#tree,#bst,#dsa'),
          fileFormat: const Value('docx'),
          fileSize: const Value(102400),
          isFavorite: const Value(false),
        ),
      );

      expect(docId, greaterThan(0));

      // Lấy chi tiết tài liệu kèm môn học
      var item = await db.documentDao.getDocumentWithSubjectById(docId);
      expect(item != null, true);
      expect(item!.document.title, 'Bài tập 1: Cây tìm kiếm nhị phân BST');
      expect(item.subject.code, 'DSA202');
      expect(item.tagList, contains('#tree'));
      expect(item.document.isFavorite, false);

      // Cập nhật trạng thái yêu thích
      await db.documentDao.toggleFavorite(docId, false);
      item = await db.documentDao.getDocumentWithSubjectById(docId);
      expect(item!.document.isFavorite, true);

      // Xóa tài liệu
      final deletedCount = await db.documentDao.deleteDocument(docId);
      expect(deletedCount, 1);

      final checkItem = await db.documentDao.getDocumentWithSubjectById(docId);
      expect(checkItem == null, true);
    });

    test('3. Kiểm thử Tìm kiếm & Lọc đa tiêu chí (Multi-criteria Filter)', () async {
      // Chuẩn bị 2 môn học mới
      final flutterId = await db.subjectDao.insertSubject(
        SubjectsCompanion.insert(name: 'Chuyên đề Đồ họa Máy tính', code: 'GRA501'),
      );
      final aiId = await db.subjectDao.insertSubject(
        SubjectsCompanion.insert(name: 'Trí tuệ Nhân tạo Ứng dụng', code: 'AII502'),
      );

      // Thêm các tài liệu có từ khóa độc nhất
      await db.documentDao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Slide Bài giảng Shader & Ray Tracing Chuyên sâu',
          documentType: DocumentType.lecture,
          subjectId: flutterId,
          tags: const Value('#raytracing,#gpu,#graphic'),
          isFavorite: const Value(true),
        ),
      );

      await db.documentDao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Đề thi Thử Nghiệm OpenGL Cuối kỳ',
          documentType: DocumentType.exam,
          subjectId: flutterId,
          tags: const Value('#onthi,#opengl,#cuoiky'),
          isFavorite: const Value(false),
        ),
      );

      await db.documentDao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Sách tham khảo: Deep Learning for Computer Vision',
          documentType: DocumentType.reference,
          subjectId: aiId,
          tags: const Value('#ai,#deeplearning,#vision'),
          isFavorite: const Value(true),
        ),
      );

      // Kịch bản A: Lọc theo từ khóa tìm kiếm độc nhất "Ray Tracing"
      var results = await db.documentDao
          .watchDocumentsWithSubject(
            filter: const DocumentFilter(searchQuery: 'Ray Tracing'),
          )
          .first;
      expect(results.length, 1);
      expect(results.first.document.title, contains('Shader & Ray Tracing'));

      // Kịch bản B: Lọc theo môn học GRA501
      results = await db.documentDao
          .watchDocumentsWithSubject(
            filter: DocumentFilter(subjectId: flutterId),
          )
          .first;
      expect(results.length, 2);
      expect(results.every((r) => r.subject.id == flutterId), true);

      // Kịch bản C: Lọc theo môn học GRA501 VÀ loại tài liệu Bài giảng
      results = await db.documentDao
          .watchDocumentsWithSubject(
            filter: DocumentFilter(
              subjectId: flutterId,
              documentType: DocumentType.lecture,
            ),
          )
          .first;
      expect(results.length, 1);
      expect(results.first.document.documentType, DocumentType.lecture);

      // Kịch bản D: Lọc kết hợp Môn GRA501 + Chỉ tài liệu Yêu thích
      results = await db.documentDao
          .watchDocumentsWithSubject(
            filter: DocumentFilter(
              subjectId: flutterId,
              isFavoriteOnly: true,
            ),
          )
          .first;
      expect(results.length, 1);
      expect(results.first.document.title, contains('Shader & Ray Tracing'));

      // Kịch bản E: Lọc theo tag độc nhất '#opengl'
      results = await db.documentDao
          .watchDocumentsWithSubject(
            filter: const DocumentFilter(tag: 'opengl'),
          )
          .first;
      expect(results.length, 1);
      expect(results.first.document.title, contains('OpenGL'));
    });
  });
}
