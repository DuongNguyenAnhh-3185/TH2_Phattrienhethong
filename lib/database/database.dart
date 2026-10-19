import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';
import 'daos/document_dao.dart';
import 'daos/subject_dao.dart';
import '../models/document_type.dart';

part 'database.g.dart';

/// Database trung tâm của ứng dụng - Áp dụng triệt để mô hình Drift của Cashew
@DriftDatabase(
  tables: [Subjects, Documents],
  daos: [SubjectDao, DocumentDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(
          e ??
              driftDatabase(
                name: 'cashew_study_docs',
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.js'),
                  onResult: (result) {
                    if (result.missingFeatures.isNotEmpty) {
                      debugPrint(
                        'Drift Web: Dùng ${result.chosenImplementation} (thiếu tính năng: ${result.missingFeatures})',
                      );
                    }
                  },
                ),
              ),
        );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Cung cấp sẵn một số môn học & tài liệu mẫu ban đầu (Initial Seed Data)
        await _seedInitialData();
      },
      beforeOpen: (details) async {
        // Bật kiểm tra khóa ngoại (Foreign Keys) cho SQLite
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }

  Future<void> _seedInitialData() async {
    final defaultSubjects = [
      SubjectsCompanion.insert(
        name: 'Lập trình Thiết bị Di động (Flutter)',
        code: 'MOB401',
        colorValue: const Value(0xFF2563EB),
        iconName: const Value('phone_android'),
      ),
      SubjectsCompanion.insert(
        name: 'Cấu trúc Dữ liệu & Giải thuật',
        code: 'DSA201',
        colorValue: const Value(0xFF7C3AED),
        iconName: const Value('account_tree'),
      ),
      SubjectsCompanion.insert(
        name: 'Hệ Quản trị Cơ sở Dữ liệu',
        code: 'DBA301',
        colorValue: const Value(0xFF059669),
        iconName: const Value('storage'),
      ),
      SubjectsCompanion.insert(
        name: 'Mạng Máy tính & Truyền thông',
        code: 'NET102',
        colorValue: const Value(0xFFD97706),
        iconName: const Value('lan'),
      ),
      SubjectsCompanion.insert(
        name: 'Kiến trúc Phần mềm',
        code: 'ARC402',
        colorValue: const Value(0xFFDC2626),
        iconName: const Value('domain'),
      ),
    ];

    for (final s in defaultSubjects) {
      await into(subjects).insert(s);
    }

    final allSubjects = await select(subjects).get();
    if (allSubjects.isNotEmpty) {
      final flutterSub = allSubjects.firstWhere(
        (s) => s.code == 'MOB401',
        orElse: () => allSubjects.first,
      );
      final dsaSub = allSubjects.firstWhere(
        (s) => s.code == 'DSA201',
        orElse: () => allSubjects.first,
      );
      final dbSub = allSubjects.firstWhere(
        (s) => s.code == 'DBA301',
        orElse: () => allSubjects.first,
      );

      await into(documents).insert(
        DocumentsCompanion.insert(
          title: 'Slide Tuần 1: Kiến trúc Flutter & Reactive State Management',
          description: const Value('Tổng quan Widget tree, Element tree, RenderObject và cơ chế phản ứng dữ liệu.'),
          documentType: DocumentType.lecture,
          subjectId: flutterSub.id,
          tags: const Value('#flutter,#state,#architecture'),
          filePath: const Value('/documents/flutter_lecture_01.pdf'),
          fileFormat: const Value('pdf'),
          fileSize: const Value(3450000), // ~3.4 MB
          isFavorite: const Value(true),
        ),
      );

      await into(documents).insert(
        DocumentsCompanion.insert(
          title: 'Bài tập lớn: Ứng dụng Quản lý Tài liệu Học tập theo Cashew',
          description: const Value('Thiết kế chuẩn phân tầng Drift/SQLite, DAOs, Provider và lọc đa tiêu chí.'),
          documentType: DocumentType.assignment,
          subjectId: flutterSub.id,
          tags: const Value('#assignment,#cashew,#drift'),
          filePath: const Value('/assignments/assignment_spec.docx'),
          fileFormat: const Value('docx'),
          fileSize: const Value(1200000), // ~1.2 MB
          isFavorite: const Value(true),
        ),
      );

      await into(documents).insert(
        DocumentsCompanion.insert(
          title: 'Bộ đề cương & Đề thi mẫu Cấu trúc Dữ liệu Cuối kỳ',
          description: const Value('Tổng hợp câu hỏi về Binary Tree, AVL, Hash Table, Dijkstra, Floyd-Warshall.'),
          documentType: DocumentType.exam,
          subjectId: dsaSub.id,
          tags: const Value('#exam,#cuoiky,#dsa'),
          filePath: const Value('/exams/dsa_final_exam_prep.pdf'),
          fileFormat: const Value('pdf'),
          fileSize: const Value(5242880), // ~5 MB
          isFavorite: const Value(false),
        ),
      );

      await into(documents).insert(
        DocumentsCompanion.insert(
          title: 'Giáo trình Thiết kế Chuẩn hóa Cơ sở Dữ liệu Quan hệ (3NF, BCNF)',
          description: const Value('Tài liệu học phần DBA: phụ thuộc hàm, bao đóng, dạng chuẩn và phân tích lược đồ.'),
          documentType: DocumentType.reference,
          subjectId: dbSub.id,
          tags: const Value('#giaotrinh,#database,#chuanhoa'),
          filePath: const Value('/books/relational_db_design.pdf'),
          fileFormat: const Value('pdf'),
          fileSize: const Value(8388608), // ~8 MB
          isFavorite: const Value(false),
        ),
      );
    }
  }
}
