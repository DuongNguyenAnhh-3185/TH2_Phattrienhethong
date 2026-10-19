import 'package:drift/drift.dart';
import '../models/document_type.dart';

/// Bảng Môn học (Subjects) - tương tự cấu trúc bảng Categories trong Cashew
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get code => text().withLength(min: 1, max: 20)();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF2563EB))();
  TextColumn get iconName => text().withDefault(const Constant('menu_book'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Bảng Tài liệu (Documents) - tương tự cấu trúc bảng Transactions/Items trong Cashew
class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  IntColumn get documentType => intEnum<DocumentType>()();
  IntColumn get subjectId => integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get filePath => text().nullable()();
  TextColumn get fileFormat => text().withDefault(const Constant('pdf'))();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
