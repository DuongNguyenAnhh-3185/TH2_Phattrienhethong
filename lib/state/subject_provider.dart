import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';

/// Provider quản lý danh mục Môn học (Subjects)
class SubjectProvider extends ChangeNotifier {
  final AppDatabase _db;

  SubjectProvider(this._db);

  /// Luồng dữ liệu phản ứng danh sách môn học
  Stream<List<Subject>> get subjectsStream => _db.subjectDao.watchAllSubjects();

  /// Lấy danh sách môn học một lần
  Future<List<Subject>> getAllSubjects() => _db.subjectDao.getAllSubjects();

  /// Thêm môn học mới
  Future<int> addSubject({
    required String name,
    required String code,
    int colorValue = 0xFF2563EB,
    String iconName = 'menu_book',
  }) async {
    final companion = SubjectsCompanion.insert(
      name: name,
      code: code,
      colorValue: Value(colorValue),
      iconName: Value(iconName),
    );

    final id = await _db.subjectDao.insertSubject(companion);
    notifyListeners();
    return id;
  }

  /// Cập nhật môn học
  Future<bool> updateSubject({
    required int id,
    required String name,
    required String code,
    int colorValue = 0xFF2563EB,
    String iconName = 'menu_book',
  }) async {
    final companion = SubjectsCompanion(
      id: Value(id),
      name: Value(name),
      code: Value(code),
      colorValue: Value(colorValue),
      iconName: Value(iconName),
    );

    final success = await _db.subjectDao.updateSubject(companion);
    notifyListeners();
    return success;
  }

  /// Xóa môn học
  Future<int> deleteSubject(int id) async {
    final rowsAffected = await _db.subjectDao.deleteSubject(id);
    notifyListeners();
    return rowsAffected;
  }
}
