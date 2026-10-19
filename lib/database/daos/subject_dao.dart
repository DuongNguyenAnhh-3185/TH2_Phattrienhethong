import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'subject_dao.g.dart';

@DriftAccessor(tables: [Subjects])
class SubjectDao extends DatabaseAccessor<AppDatabase> with _$SubjectDaoMixin {
  SubjectDao(super.db);

  /// Lắng nghe luồng dữ liệu danh sách môn học theo thời gian thực (Reactive Stream)
  Stream<List<Subject>> watchAllSubjects() {
    return (select(subjects)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Lấy toàn bộ danh sách môn học một lần
  Future<List<Subject>> getAllSubjects() {
    return (select(subjects)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  /// Lấy thông tin một môn học theo ID
  Future<Subject?> getSubjectById(int id) {
    return (select(subjects)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Thêm môn học mới
  Future<int> insertSubject(SubjectsCompanion entry) {
    return into(subjects).insert(entry);
  }

  /// Cập nhật môn học
  Future<bool> updateSubject(SubjectsCompanion entry) {
    return (update(subjects)..where((t) => t.id.equals(entry.id.value))).write(entry).then((count) => count > 0);
  }

  /// Xóa môn học theo ID
  Future<int> deleteSubject(int id) {
    return (delete(subjects)..where((t) => t.id.equals(id))).go();
  }
}
