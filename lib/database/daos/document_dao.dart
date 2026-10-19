import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';
import '../../models/document_filter.dart';
import '../../models/document_with_subject.dart';

part 'document_dao.g.dart';

@DriftAccessor(tables: [Documents, Subjects])
class DocumentDao extends DatabaseAccessor<AppDatabase> with _$DocumentDaoMixin {
  DocumentDao(super.db);

  /// Lắng nghe luồng dữ liệu tài liệu kèm môn học với bộ lọc đa tiêu chí
  Stream<List<DocumentWithSubject>> watchDocumentsWithSubject({DocumentFilter? filter}) {
    final query = select(documents).join([
      innerJoin(subjects, subjects.id.equalsExp(documents.subjectId)),
    ]);

    if (filter != null) {
      // 1. Lọc theo từ khóa tìm kiếm (Tiêu đề, Mô tả hoặc Tags)
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final rawTerm = filter.searchQuery!.trim().toLowerCase();
        final searchPattern = '%$rawTerm%';
        query.where(
          documents.title.lower().like(searchPattern) |
          documents.description.lower().like(searchPattern) |
          documents.tags.lower().like(searchPattern),
        );
      }

      // 2. Lọc theo Môn học
      if (filter.subjectId != null) {
        query.where(documents.subjectId.equals(filter.subjectId!));
      }

      // 3. Lọc theo Loại tài liệu (Bài giảng / Bài tập / Tham khảo / Đề thi)
      if (filter.documentType != null) {
        query.where(documents.documentType.equals(filter.documentType!.index));
      }

      // 4. Lọc chỉ tài liệu yêu thích
      if (filter.isFavoriteOnly) {
        query.where(documents.isFavorite.equals(true));
      }

      // 5. Lọc theo tag
      if (filter.tag != null && filter.tag!.trim().isNotEmpty) {
        query.where(documents.tags.lower().like('%${filter.tag!.trim().toLowerCase()}%'));
      }

      // 6. Sắp xếp kết quả
      switch (filter.sortBy) {
        case SortOption.newest:
          query.orderBy([OrderingTerm.desc(documents.createdAt)]);
          break;
        case SortOption.oldest:
          query.orderBy([OrderingTerm.asc(documents.createdAt)]);
          break;
        case SortOption.titleAsc:
          query.orderBy([OrderingTerm.asc(documents.title.lower())]);
          break;
        case SortOption.titleDesc:
          query.orderBy([OrderingTerm.desc(documents.title.lower())]);
          break;
      }
    } else {
      query.orderBy([OrderingTerm.desc(documents.createdAt)]);
    }

    return query.watch().map((rows) {
      return rows.map((row) {
        return DocumentWithSubject(
          document: row.readTable(documents),
          subject: row.readTable(subjects),
        );
      }).toList();
    });
  }

  /// Lấy chi tiết 1 tài liệu kèm môn học
  Future<DocumentWithSubject?> getDocumentWithSubjectById(int id) async {
    final query = select(documents).join([
      innerJoin(subjects, subjects.id.equalsExp(documents.subjectId)),
    ])..where(documents.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return DocumentWithSubject(
      document: row.readTable(documents),
      subject: row.readTable(subjects),
    );
  }

  /// Thêm mới tài liệu
  Future<int> insertDocument(DocumentsCompanion entry) {
    return into(documents).insert(entry);
  }

  /// Cập nhật tài liệu
  Future<bool> updateDocument(DocumentsCompanion entry) {
    return (update(documents)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((count) => count > 0);
  }

  /// Bật/tắt trạng thái yêu thích
  Future<bool> toggleFavorite(int id, bool currentStatus) {
    return (update(documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(
          isFavorite: Value(!currentStatus),
          updatedAt: Value(DateTime.now()),
        ))
        .then((count) => count > 0);
  }

  /// Xóa tài liệu khỏi hệ thống
  Future<int> deleteDocument(int id) {
    return (delete(documents)..where((t) => t.id.equals(id))).go();
  }

  /// Lấy tổng số lượng tài liệu theo thời gian thực
  Stream<int> watchDocumentCount() {
    final countExp = documents.id.count();
    final query = selectOnly(documents)..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Lấy số lượng tài liệu yêu thích
  Stream<int> watchFavoriteCount() {
    final countExp = documents.id.count();
    final query = selectOnly(documents)
      ..where(documents.isFavorite.equals(true))
      ..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }
}
